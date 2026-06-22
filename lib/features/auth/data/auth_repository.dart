import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/app_user.dart';

/// Single-login model: one Firebase account per family. Children are profiles
/// (member docs) inside the family, not separate accounts.
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

  /// Create the family account.
  Future<User> signUpParent(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user!;
  }

  /// Sign in to the family account.
  Future<User> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user!;
  }

  /// Guest / explore mode: an anonymous session so someone can try the app
  /// without creating an account. Guest data lives only on this device and
  /// can't be recovered elsewhere.
  Future<User> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    return credential.user!;
  }

  /// Send a password reset email for the (grown-up) family account.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Store the account → family mapping (`userProfiles/{uid}` → {familyId}).
  Future<void> saveUserProfile(AppUser appUser) async {
    await _firestore
        .collection('userProfiles')
        .doc(appUser.uid)
        .set(appUser.toMap());
  }

  /// Get the account → family mapping.
  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('userProfiles').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromMap(doc.data()!);
  }

  Future<void> deleteUserProfile(String uid) async {
    await _firestore.collection('userProfiles').doc(uid).delete();
  }

  /// Recover the mapping for a signed-in account whose `userProfiles` doc is
  /// missing (e.g. an interrupted signup) by finding the family they own.
  Future<AppUser?> recoverUserProfile(User user) async {
    final ownedFamilies = await _firestore
        .collection('families')
        .where('parentUid', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (ownedFamilies.docs.isEmpty) return null;

    final rebuilt = AppUser(
      uid: user.uid,
      email: user.email,
      familyId: ownedFamilies.docs.first.id,
    );
    await saveUserProfile(rebuilt);
    return rebuilt;
  }
}
