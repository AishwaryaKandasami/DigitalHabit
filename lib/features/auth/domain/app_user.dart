/// Member role within a family. With the single-login model the signed-in
/// account is the family owner; member docs are child profiles. The enum is
/// kept for member docs (and legacy data) but no longer lives on [AppUser].
enum UserRole { parent, child }

/// The signed-in family account. There is exactly one login per family; the
/// children are profiles ([MemberModel]) inside the family, selected via the
/// active-profile provider — not separate accounts.
class AppUser {
  final String uid;
  final String? email;
  final String? familyId;

  const AppUser({
    required this.uid,
    this.email,
    this.familyId,
  });

  bool get hasFamily => familyId != null;

  AppUser copyWith({
    String? uid,
    String? email,
    String? familyId,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      familyId: familyId ?? this.familyId,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'familyId': familyId,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        uid: map['uid'] as String,
        email: map['email'] as String?,
        familyId: map['familyId'] as String?,
      );
}
