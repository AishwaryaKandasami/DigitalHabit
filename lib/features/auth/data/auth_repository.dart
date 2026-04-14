import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../firebase_options.dart';
import '../domain/app_user.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  User? get currentFirebaseUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up parent with email and password.
  Future<User> signUpParent(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user!;
  }

  /// Sign in with email and password.
  Future<User> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user!;
  }

  /// Sign in anonymously (for kids joining a family).
  ///
  /// Retained for backwards compatibility with existing anonymous kid accounts.
  /// New kid accounts should use [createChildAccount] (email/password).
  Future<User> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    return credential.user!;
  }

  /// Create a child email/password account using a secondary Firebase app so
  /// the parent's session on this device is NOT replaced. The parent stays
  /// signed in; the returned [User] represents the kid's account.
  Future<User> createChildAccount(String email, String password) async {
    final appName =
        'kidCreator-${DateTime.now().microsecondsSinceEpoch}';
    final secondaryApp = await Firebase.initializeApp(
      name: appName,
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Sign out the secondary auth so the kid isn't left signed in on the
      // parent's device.
      await secondaryAuth.signOut();
      return cred.user!;
    } finally {
      await secondaryApp.delete();
    }
  }

  /// Send a password reset email (used when a kid forgets their password;
  /// the email lands in whatever inbox the parent registered for them).
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Sign out.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Store user profile mapping (uid -> familyId, role, memberId).
  Future<void> saveUserProfile(AppUser appUser) async {
    await _firestore
        .collection('userProfiles')
        .doc(appUser.uid)
        .set(appUser.toMap());
  }

  /// Get user profile from Firestore.
  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('userProfiles').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromMap(doc.data()!);
  }

  /// Delete user profile from Firestore (when parent removes a kid).
  Future<void> deleteUserProfile(String uid) async {
    await _firestore.collection('userProfiles').doc(uid).delete();
  }

  /// Attempt to recover the userProfile for a signed-in user whose mapping
  /// doc is missing (e.g. an earlier aborted signup). Searches for a family
  /// they own (parent) or a member doc with a matching authUid (any role).
  /// Writes the rebuilt profile and returns it, or null if nothing found.
  Future<AppUser?> recoverUserProfile(User user) async {
    // Case 1: user is the parent (owner) of some family.
    final ownedFamilies = await _firestore
        .collection('families')
        .where('parentUid', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (ownedFamilies.docs.isNotEmpty) {
      final familyId = ownedFamilies.docs.first.id;
      // Find the parent's member doc in that family.
      final memberQuery = await _firestore
          .collection('families')
          .doc(familyId)
          .collection('members')
          .where('authUid', isEqualTo: user.uid)
          .limit(1)
          .get();
      String memberId;
      String roleName;
      if (memberQuery.docs.isNotEmpty) {
        final memberDoc = memberQuery.docs.first;
        memberId = memberDoc.id;
        roleName = memberDoc.data()['role'] as String? ?? 'parent';
      } else {
        // Family exists but parent has no member doc yet — create one.
        final newMember = _firestore
            .collection('families')
            .doc(familyId)
            .collection('members')
            .doc();
        await newMember.set({
          'displayName': 'Parent',
          'role': 'parent',
          'authUid': user.uid,
          'avatarState': {},
          'wallet': {'coins': 0, 'totalEarned': 0},
          'inventory': <dynamic>[],
          'streakDays': 0,
          'lastActiveDate': null,
        });
        memberId = newMember.id;
        roleName = 'parent';
      }
      final rebuilt = AppUser(
        uid: user.uid,
        email: user.email,
        familyId: familyId,
        memberId: memberId,
        role: UserRole.values.byName(roleName),
      );
      await saveUserProfile(rebuilt);
      return rebuilt;
    }

    // Case 2: user is a member (kid) somewhere — try collectionGroup.
    try {
      final memberQuery = await _firestore
          .collectionGroup('members')
          .where('authUid', isEqualTo: user.uid)
          .limit(1)
          .get();
      if (memberQuery.docs.isNotEmpty) {
        final memberDoc = memberQuery.docs.first;
        // memberDoc.reference.path looks like
        // "families/{familyId}/members/{memberId}"
        final segments = memberDoc.reference.path.split('/');
        final familyId = segments[1];
        final roleName = memberDoc.data()['role'] as String? ?? 'child';
        final rebuilt = AppUser(
          uid: user.uid,
          email: user.email,
          familyId: familyId,
          memberId: memberDoc.id,
          role: UserRole.values.byName(roleName),
        );
        await saveUserProfile(rebuilt);
        return rebuilt;
      }
    } catch (_) {
      // collectionGroup may require an index; swallow and return null.
    }

    return null;
  }
}
