import '../../../core/constants/game_constants.dart';
import 'avatar_state.dart';

class EvolutionCalculator {
  /// Calculate the evolution stage based on total XP.
  static int calculateStage(int totalXp) {
    for (int i = GameConstants.evolutionXpThresholds.length - 1; i >= 0; i--) {
      if (totalXp >= GameConstants.evolutionXpThresholds[i]) return i + 1;
    }
    return 1;
  }

  /// Calculate level (each evolution stage has sub-levels).
  static int calculateLevel(int totalXp) {
    final stage = calculateStage(totalXp);
    if (stage == 1) return 1;
    final prevThreshold = GameConstants.evolutionXpThresholds[stage - 1];
    final currentThreshold = stage < GameConstants.evolutionXpThresholds.length
        ? GameConstants.evolutionXpThresholds[stage]
        : GameConstants.evolutionXpThresholds.last + 1000;
    final xpInStage = totalXp - prevThreshold;
    final stageRange = currentThreshold - prevThreshold;
    return (stage - 1) * 5 + (xpInStage * 5 ~/ stageRange) + 1;
  }

  /// Add XP and return updated avatar state with possible evolution.
  static AvatarState addXp(AvatarState state, int xpGained) {
    final newTotalXp = state.totalXp + xpGained;
    final newStage = calculateStage(newTotalXp);
    final newLevel = calculateLevel(newTotalXp);
    return state.copyWith(
      totalXp: newTotalXp,
      evolutionStage: newStage,
      level: newLevel,
    );
  }

  /// Apply mood change and clamp to 0-100.
  static AvatarState applyMoodChange(AvatarState state, int delta) {
    final newMood =
        (state.moodScore + delta).clamp(0, GameConstants.moodMax);
    return state.copyWith(moodScore: newMood);
  }

  /// Apply health change and clamp to 0-100.
  static AvatarState applyHealthChange(AvatarState state, int delta) {
    final newHealth =
        (state.health + delta).clamp(0, GameConstants.healthMax);
    return state.copyWith(health: newHealth);
  }

  /// Apply daily mood decay based on days since last active.
  static AvatarState applyMoodDecay(AvatarState state, int daysMissed) {
    if (daysMissed <= 0) return state;
    final totalDecay = daysMissed * GameConstants.moodDailyDecay;
    return applyMoodChange(state, totalDecay);
  }

  /// Determine health trajectory based on healthy task ratio.
  static int healthDelta(double healthyRatio) {
    if (healthyRatio >= GameConstants.healthyRatioGood) {
      return GameConstants.healthRegenPerDay;
    }
    if (healthyRatio < GameConstants.healthyRatioBad) {
      return GameConstants.healthDropPerDay;
    }
    return 0; // stable
  }
}
