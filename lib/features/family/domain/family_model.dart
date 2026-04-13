import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyModel {
  final String id;
  final String name;
  final String parentUid;
  final String inviteCode;
  final DateTime createdAt;
  final FamilySettings settings;

  const FamilyModel({
    required this.id,
    required this.name,
    required this.parentUid,
    required this.inviteCode,
    required this.createdAt,
    required this.settings,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'parentUid': parentUid,
        'inviteCode': inviteCode,
        'createdAt': Timestamp.fromDate(createdAt),
        'settings': settings.toMap(),
      };

  factory FamilyModel.fromMap(String id, Map<String, dynamic> map) =>
      FamilyModel(
        id: id,
        name: map['name'] as String,
        parentUid: map['parentUid'] as String,
        inviteCode: map['inviteCode'] as String,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        settings: FamilySettings.fromMap(
            map['settings'] as Map<String, dynamic>? ?? {}),
      );
}

class FamilySettings {
  final bool requireParentVerification;
  final String weekStartsOn;
  final int maxScreenTimeMinutes;

  const FamilySettings({
    this.requireParentVerification = true,
    this.weekStartsOn = 'monday',
    this.maxScreenTimeMinutes = 120,
  });

  Map<String, dynamic> toMap() => {
        'requireParentVerification': requireParentVerification,
        'weekStartsOn': weekStartsOn,
        'maxScreenTimeMinutes': maxScreenTimeMinutes,
      };

  factory FamilySettings.fromMap(Map<String, dynamic> map) => FamilySettings(
        requireParentVerification:
            map['requireParentVerification'] as bool? ?? true,
        weekStartsOn: map['weekStartsOn'] as String? ?? 'monday',
        maxScreenTimeMinutes: map['maxScreenTimeMinutes'] as int? ?? 120,
      );
}
