import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  Future<User> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    return credential.user!;
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
}
