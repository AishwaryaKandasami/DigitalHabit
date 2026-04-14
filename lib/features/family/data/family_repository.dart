import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/utils/id_generator.dart';
import '../../auth/domain/app_user.dart';
import '../../avatar/domain/avatar_state.dart';
import '../domain/family_model.dart';
import '../domain/member_model.dart';

class FamilyRepository {
  final FirebaseFirestore _firestore;

  FamilyRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new family with an invite code.
  Future<FamilyModel> createFamily({
    required String name,
    required String parentUid,
  }) async {
    final inviteCode = IdGenerator.inviteCode();
    final docRef = _firestore.collection(FirestorePaths.families).doc();
    final family = FamilyModel(
      id: docRef.id,
      name: name,
      parentUid: parentUid,
      inviteCode: inviteCode,
      createdAt: DateTime.now(),
      settings: const FamilySettings(),
    );
    await docRef.set(family.toMap());
    return family;
  }

  /// Find family by invite code.
  Future<FamilyModel?> findByInviteCode(String code) async {
    final query = await _firestore
        .collection(FirestorePaths.families)
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return FamilyModel.fromMap(doc.id, doc.data());
  }

  /// Get family by ID.
  Future<FamilyModel?> getFamily(String familyId) async {
    final doc = await _firestore
        .collection(FirestorePaths.families)
        .doc(familyId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return FamilyModel.fromMap(doc.id, doc.data()!);
  }

  /// Stream family document.
  Stream<FamilyModel?> streamFamily(String familyId) {
    return _firestore
        .collection(FirestorePaths.families)
        .doc(familyId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return FamilyModel.fromMap(doc.id, doc.data()!);
    });
  }

  /// Add a member to a family.
  Future<MemberModel> addMember({
    required String familyId,
    required String displayName,
    required UserRole role,
    String? authUid,
    String? email,
    AvatarState? avatarState,
  }) async {
    final docRef = _firestore
        .collection(FirestorePaths.members(familyId))
        .doc();
    final member = MemberModel(
      id: docRef.id,
      displayName: displayName,
      role: role,
      authUid: authUid,
      email: email,
      avatarState: avatarState ?? const AvatarState(),
      wallet: const Wallet(),
    );
    await docRef.set(member.toMap());
    return member;
  }

  /// Get all members of a family.
  Future<List<MemberModel>> getMembers(String familyId) async {
    final query =
        await _firestore.collection(FirestorePaths.members(familyId)).get();
    return query.docs
        .map((doc) => MemberModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Stream members of a family.
  Stream<List<MemberModel>> streamMembers(String familyId) {
    return _firestore
        .collection(FirestorePaths.members(familyId))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MemberModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Get a specific member.
  Future<MemberModel?> getMember(String familyId, String memberId) async {
    final doc = await _firestore
        .collection(FirestorePaths.members(familyId))
        .doc(memberId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return MemberModel.fromMap(doc.id, doc.data()!);
  }

  /// Delete a member from a family.
  Future<void> deleteMember(String familyId, String memberId) async {
    await _firestore
        .collection(FirestorePaths.members(familyId))
        .doc(memberId)
        .delete();
  }

  /// Update member document (e.g., avatar state, wallet).
  Future<void> updateMember(
    String familyId,
    String memberId,
    Map<String, dynamic> data,
  ) async {
    await _firestore
        .collection(FirestorePaths.members(familyId))
        .doc(memberId)
        .update(data);
  }

  /// Add a custom category name to the family's category list.
  Future<void> addCustomCategory(String familyId, String categoryName) async {
    await _firestore
        .collection(FirestorePaths.families)
        .doc(familyId)
        .update({
      'customCategories': FieldValue.arrayUnion([categoryName]),
    });
  }

  /// Remove a custom category name from the family's category list.
  Future<void> removeCustomCategory(
      String familyId, String categoryName) async {
    await _firestore
        .collection(FirestorePaths.families)
        .doc(familyId)
        .update({
      'customCategories': FieldValue.arrayRemove([categoryName]),
    });
  }
}
