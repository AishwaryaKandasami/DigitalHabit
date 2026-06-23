import 'package:flutter_test/flutter_test.dart';
import 'package:habit_quest/features/auth/domain/app_user.dart';
import 'package:habit_quest/features/avatar/domain/avatar_state.dart';
import 'package:habit_quest/features/family/domain/member_model.dart';
import 'package:habit_quest/features/planner/domain/task_category.dart';
import 'package:habit_quest/features/garden/application/garden_builder.dart';
import 'package:habit_quest/features/garden/domain/garden_plant.dart';

MemberModel _member({
  Map<String, int> gardenDays = const {},
  Map<String, String> gardenLastDate = const {},
  int streakDays = 0,
}) {
  return MemberModel(
    id: 'm1',
    displayName: 'Kid',
    role: UserRole.child,
    avatarState: const AvatarState(),
    wallet: const Wallet(),
    gardenDays: gardenDays,
    gardenLastDate: gardenLastDate,
    streakDays: streakDays,
  );
}

void main() {
  group('GardenBuilder', () {
    test('grows one plant per habit category with days > 0, most-grown first',
        () {
      final state = GardenBuilder.build(
        member: _member(gardenDays: {'exercise': 5, 'study': 1}),
      );
      expect(state.plants.length, 2);
      expect(state.plants.first.category, TaskCategory.exercise);
      expect(state.plants.first.species, PlantSpecies.tree);
      expect(state.plants.first.stage, PlantStage.leafy); // 5 days

      final study =
          state.plants.firstWhere((p) => p.category == TaskCategory.study);
      expect(study.species, PlantSpecies.flower);
      expect(study.stage, PlantStage.sprout); // 1 day
    });

    test('ignores zero-day categories and the unhealthy screenTime category',
        () {
      final state = GardenBuilder.build(
        member: _member(gardenDays: {'chores': 0, 'screenTime': 9}),
      );
      expect(state.plants, isEmpty);
    });

    test('growth rises with days and clamps to 1.0 at full bloom', () {
      final low =
          GardenBuilder.build(member: _member(gardenDays: {'exercise': 2}));
      final high =
          GardenBuilder.build(member: _member(gardenDays: {'exercise': 40}));
      expect(low.plants.first.growth, lessThan(high.plants.first.growth));
      expect(high.plants.first.growth, 1.0);
      expect(high.plants.first.stage, PlantStage.blooming);
    });

    test('carries streak/mood/health from the member', () {
      final state = GardenBuilder.build(
        member: _member(gardenDays: {'sleep': 3}, streakDays: 6),
      );
      expect(state.streakDays, 6);
      expect(state.plants.first.species, PlantSpecies.creeper);
    });
  });

  test('MemberModel round-trips garden fields through toMap/fromMap', () {
    final m = _member(
      gardenDays: {'exercise': 4, 'study': 2},
      gardenLastDate: {'exercise': '2026-06-23'},
    );
    final restored = MemberModel.fromMap(m.id, m.toMap());
    expect(restored.gardenDays, {'exercise': 4, 'study': 2});
    expect(restored.gardenLastDate, {'exercise': '2026-06-23'});
  });
}
