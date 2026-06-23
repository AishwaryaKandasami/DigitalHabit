import '../../planner/domain/task_category.dart';

/// The kind of plant that represents a habit category in the garden.
enum PlantSpecies { tree, flower, veggies, creeper, bush, tulips }

/// Which species grows for each habit category. The unhealthy `screenTime`
/// category is intentionally absent — it grows no plant (all-positive tone).
const Map<TaskCategory, PlantSpecies> kCategoryPlant = {
  TaskCategory.exercise: PlantSpecies.tree,
  TaskCategory.study: PlantSpecies.flower,
  TaskCategory.chores: PlantSpecies.veggies,
  TaskCategory.creative: PlantSpecies.tulips,
  TaskCategory.social: PlantSpecies.bush,
  TaskCategory.sleep: PlantSpecies.creeper,
  TaskCategory.custom: PlantSpecies.flower,
};

/// Lifecycle stage of a plant, derived from how many days its habit was done.
enum PlantStage { seed, sprout, leafy, budding, blooming }

/// Days of consistency at which a plant reaches full bloom — drives the 0..1
/// growth fraction fed to a Rive `growth` input.
const int kPlantBloomDays = 21;

/// One plant in the garden: a habit category, its species, and how grown it is.
class GardenPlant {
  final TaskCategory category;
  final PlantSpecies species;

  /// Cumulative days the kid completed this habit. Monotonic — never decreases.
  final int days;

  const GardenPlant({
    required this.category,
    required this.species,
    required this.days,
  });

  PlantStage get stage => stageForDays(days);

  /// 0..1 growth, for driving a Rive state-machine input or scaling a widget.
  double get growth => (days / kPlantBloomDays).clamp(0.0, 1.0).toDouble();

  static PlantStage stageForDays(int days) {
    if (days <= 0) return PlantStage.seed;
    if (days < 3) return PlantStage.sprout;
    if (days < 7) return PlantStage.leafy;
    if (days < 14) return PlantStage.budding;
    return PlantStage.blooming;
  }

  /// The plant species for a category, or null if that category grows nothing.
  static PlantSpecies? speciesFor(TaskCategory category) =>
      kCategoryPlant[category];
}
