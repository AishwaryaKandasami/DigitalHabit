import 'package:flutter_test/flutter_test.dart';
import 'package:habit_quest/features/avatar/domain/evolution_calculator.dart';
import 'package:habit_quest/features/avatar/domain/avatar_state.dart';
import 'package:habit_quest/features/avatar/domain/creature_type.dart';

void main() {
  group('EvolutionCalculator', () {
    test('calculateStage returns correct stage for XP values', () {
      expect(EvolutionCalculator.calculateStage(0), 1);
      expect(EvolutionCalculator.calculateStage(50), 1);
      expect(EvolutionCalculator.calculateStage(100), 2);
      expect(EvolutionCalculator.calculateStage(499), 2);
      expect(EvolutionCalculator.calculateStage(500), 3);
      expect(EvolutionCalculator.calculateStage(1500), 4);
      expect(EvolutionCalculator.calculateStage(4000), 5);
      expect(EvolutionCalculator.calculateStage(9999), 5);
    });

    test('addXp updates totalXp and triggers evolution', () {
      const state = AvatarState(
        creatureName: 'Test',
        creatureType: CreatureType.fireFox,
        totalXp: 90,
        evolutionStage: 1,
        level: 1,
      );

      final updated = EvolutionCalculator.addXp(state, 15);
      expect(updated.totalXp, 105);
      expect(updated.evolutionStage, 2);
    });

    test('applyMoodChange clamps between 0 and 100', () {
      const state = AvatarState(moodScore: 5);
      final decreased = EvolutionCalculator.applyMoodChange(state, -10);
      expect(decreased.moodScore, 0);

      const highState = AvatarState(moodScore: 95);
      final increased = EvolutionCalculator.applyMoodChange(highState, 10);
      expect(increased.moodScore, 100);
    });

    test('applyMoodDecay reduces mood per day missed', () {
      const state = AvatarState(moodScore: 75);
      final decayed = EvolutionCalculator.applyMoodDecay(state, 3);
      expect(decayed.moodScore, 60);
    });

    test('healthDelta returns correct values based on ratio', () {
      expect(EvolutionCalculator.healthDelta(0.8), 5);
      expect(EvolutionCalculator.healthDelta(0.5), 0);
      expect(EvolutionCalculator.healthDelta(0.3), -10);
    });
  });
}
