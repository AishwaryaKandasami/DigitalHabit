import '../../family/domain/member_model.dart';
import '../../planner/domain/task_category.dart';
import '../domain/garden_plant.dart';
import '../domain/garden_state.dart';

/// Builds a [GardenState] purely from a [MemberModel]. No I/O, no Rive — this
/// is the single source of "what grows", so the visual layer can change freely
/// and the logic stays unit-testable.
class GardenBuilder {
  GardenBuilder._();

  static GardenState build({required MemberModel member, DateTime? now}) {
    final plants = <GardenPlant>[];

    member.gardenDays.forEach((categoryName, days) {
      if (days <= 0) return;
      final category = _categoryByName(categoryName);
      if (category == null) return;
      final species = GardenPlant.speciesFor(category);
      if (species == null) return; // unhealthy/unknown category → no plant
      plants.add(GardenPlant(
        category: category,
        species: species,
        days: days,
      ));
    });

    // Most-grown first, then stable by category order.
    plants.sort((a, b) => b.days != a.days
        ? b.days.compareTo(a.days)
        : a.category.index.compareTo(b.category.index));

    final avatar = member.avatarState;
    return GardenState(
      plants: plants,
      streakDays: member.streakDays,
      evolutionStage: avatar.evolutionStage,
      moodScore: avatar.moodScore,
      health: avatar.health,
    );
  }

  static TaskCategory? _categoryByName(String name) {
    for (final c in TaskCategory.values) {
      if (c.name == name) return c;
    }
    return null;
  }
}
