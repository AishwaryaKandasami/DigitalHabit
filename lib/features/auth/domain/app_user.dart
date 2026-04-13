enum UserRole { parent, child }

class AppUser {
  final String uid;
  final String? email;
  final String? familyId;
  final String? memberId;
  final UserRole? role;

  const AppUser({
    required this.uid,
    this.email,
    this.familyId,
    this.memberId,
    this.role,
  });

  bool get hasFamily => familyId != null;
  bool get isParent => role == UserRole.parent;
  bool get isChild => role == UserRole.child;

  AppUser copyWith({
    String? uid,
    String? email,
    String? familyId,
    String? memberId,
    UserRole? role,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      familyId: familyId ?? this.familyId,
      memberId: memberId ?? this.memberId,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'familyId': familyId,
        'memberId': memberId,
        'role': role?.name,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        uid: map['uid'] as String,
        email: map['email'] as String?,
        familyId: map['familyId'] as String?,
        memberId: map['memberId'] as String?,
        role: map['role'] != null
            ? UserRole.values.byName(map['role'] as String)
            : null,
      );
}
