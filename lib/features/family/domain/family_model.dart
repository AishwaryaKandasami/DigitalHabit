import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyModel {
  final String id;
  final String name;
  final String parentUid;
  final String inviteCode;
  final DateTime createdAt;
  final FamilySettings settings;
  final List<String> customCategories;

  const FamilyModel({
    required this.id,
    required this.name,
    required this.parentUid,
    required this.inviteCode,
    required this.createdAt,
    required this.settings,
    this.customCategories = const [],
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'parentUid': parentUid,
        'inviteCode': inviteCode,
        'createdAt': Timestamp.fromDate(createdAt),
        'settings': settings.toMap(),
        'customCategories': customCategories,
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
        customCategories: (map['customCategories'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}

class FamilySettings {
  final String weekStartsOn;
  final int maxScreenTimeMinutes;

  /// 4-digit PIN gating the grown-up area. Null until set during setup.
  final String? grownupPin;

  const FamilySettings({
    this.weekStartsOn = 'monday',
    this.maxScreenTimeMinutes = 120,
    this.grownupPin,
  });

  Map<String, dynamic> toMap() => {
        'weekStartsOn': weekStartsOn,
        'maxScreenTimeMinutes': maxScreenTimeMinutes,
        'grownupPin': grownupPin,
      };

  factory FamilySettings.fromMap(Map<String, dynamic> map) => FamilySettings(
        weekStartsOn: map['weekStartsOn'] as String? ?? 'monday',
        maxScreenTimeMinutes: map['maxScreenTimeMinutes'] as int? ?? 120,
        grownupPin: map['grownupPin'] as String?,
      );

  FamilySettings copyWith({
    String? weekStartsOn,
    int? maxScreenTimeMinutes,
    String? grownupPin,
  }) =>
      FamilySettings(
        weekStartsOn: weekStartsOn ?? this.weekStartsOn,
        maxScreenTimeMinutes: maxScreenTimeMinutes ?? this.maxScreenTimeMinutes,
        grownupPin: grownupPin ?? this.grownupPin,
      );
}
