import '../../../core/constants/game_constants.dart';
import 'creature_type.dart';

class AvatarState {
  final String creatureName;
  final CreatureType creatureType;
  final int level;
  final int totalXp;
  final int evolutionStage; // 1-5
  final int moodScore; // 0-100
  final int health; // 0-100
  final DateTime? lastFedAt;
  final List<String> accessories;

  const AvatarState({
    this.creatureName = '',
    this.creatureType = CreatureType.fireFox,
    this.level = 1,
    this.totalXp = 0,
    this.evolutionStage = 1,
    this.moodScore = 75,
    this.health = 100,
    this.lastFedAt,
    this.accessories = const [],
  });

  String get evolutionStageName =>
      GameConstants.evolutionStageNames[evolutionStage - 1];

  String get moodLabel {
    if (moodScore >= GameConstants.moodHappyThreshold) return 'Happy';
    if (moodScore >= GameConstants.moodNeutralThreshold) return 'Neutral';
    if (moodScore >= GameConstants.moodSadThreshold) return 'Sad';
    return 'Sick';
  }

  int get xpForCurrentLevel {
    if (evolutionStage >= GameConstants.evolutionXpThresholds.length) {
      return totalXp;
    }
    return totalXp - GameConstants.evolutionXpThresholds[evolutionStage - 1];
  }

  int get xpToNextLevel {
    if (evolutionStage >= GameConstants.evolutionXpThresholds.length) return 0;
    return GameConstants.evolutionXpThresholds[evolutionStage] -
        GameConstants.evolutionXpThresholds[evolutionStage - 1];
  }

  Map<String, dynamic> toMap() => {
        'creatureName': creatureName,
        'creatureType': creatureType.name,
        'level': level,
        'totalXp': totalXp,
        'evolutionStage': evolutionStage,
        'moodScore': moodScore,
        'health': health,
        'lastFedAt': lastFedAt?.toIso8601String(),
        'accessories': accessories,
      };

  factory AvatarState.fromMap(Map<String, dynamic> map) {
    if (map.isEmpty) return const AvatarState();
    return AvatarState(
      creatureName: map['creatureName'] as String? ?? '',
      creatureType: map['creatureType'] != null
          ? CreatureType.values.byName(map['creatureType'] as String)
          : CreatureType.fireFox,
      level: map['level'] as int? ?? 1,
      totalXp: map['totalXp'] as int? ?? 0,
      evolutionStage: map['evolutionStage'] as int? ?? 1,
      moodScore: map['moodScore'] as int? ?? 75,
      health: map['health'] as int? ?? 100,
      lastFedAt: map['lastFedAt'] != null
          ? DateTime.parse(map['lastFedAt'] as String)
          : null,
      accessories: List<String>.from(map['accessories'] ?? []),
    );
  }

  AvatarState copyWith({
    String? creatureName,
    CreatureType? creatureType,
    int? level,
    int? totalXp,
    int? evolutionStage,
    int? moodScore,
    int? health,
    DateTime? lastFedAt,
    List<String>? accessories,
  }) {
    return AvatarState(
      creatureName: creatureName ?? this.creatureName,
      creatureType: creatureType ?? this.creatureType,
      level: level ?? this.level,
      totalXp: totalXp ?? this.totalXp,
      evolutionStage: evolutionStage ?? this.evolutionStage,
      moodScore: moodScore ?? this.moodScore,
      health: health ?? this.health,
      lastFedAt: lastFedAt ?? this.lastFedAt,
      accessories: accessories ?? this.accessories,
    );
  }
}
