import 'garden_plant.dart';

/// A derived, read-only view of the kid's garden, built from member data by
/// [GardenBuilder]. This is the single source of "what grows", so the visual
/// layer (code-drawn now, Rive later) can change without touching this.
class GardenState {
  /// Plants the kid has grown, most-grown first.
  final List<GardenPlant> plants;

  /// Current streak — drives weather/liveliness (sun, sparkle), not growth.
  final int streakDays;

  final int evolutionStage;
  final int moodScore;
  final int health;

  const GardenState({
    this.plants = const [],
    this.streakDays = 0,
    this.evolutionStage = 1,
    this.moodScore = 0,
    this.health = 0,
  });

  bool get isEmpty => plants.isEmpty;

  /// Total days of consistency across all habits — a simple "garden size".
  int get totalDays => plants.fold(0, (sum, p) => sum + p.days);
}
