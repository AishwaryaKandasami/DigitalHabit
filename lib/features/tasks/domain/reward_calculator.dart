import '../../../core/constants/game_constants.dart';

class RewardResult {
  final int coins;
  final int xp;

  const RewardResult({required this.coins, required this.xp});
}

class RewardCalculator {
  RewardCalculator._();

  /// Calculate coins and XP for completing a single task.
  static RewardResult forTaskCompletion({required bool isHealthy}) {
    final coins =
        isHealthy ? GameConstants.coinsHealthyTask : GameConstants.coinsAnyTask;
    final xp =
        isHealthy ? GameConstants.xpHealthyTask : GameConstants.xpAnyTask;
    return RewardResult(coins: coins, xp: xp);
  }

  /// Bonus for parent verification.
  static const verificationBonus =
      RewardResult(coins: 5, xp: GameConstants.xpParentVerifiedBonus);

  /// Bonus for completing all tasks in a day.
  static const fullDayBonus = RewardResult(
    coins: GameConstants.coinsFullDayBonus,
    xp: GameConstants.xpFullDayBonus,
  );

  /// Bonus for completing all tasks in a week.
  static const fullWeekBonus = RewardResult(
    coins: GameConstants.coinsFullWeekBonus,
    xp: 0,
  );

  /// Bonus for 7-day streak.
  static const streakBonus = RewardResult(
    coins: GameConstants.coinsStreakBonus,
    xp: GameConstants.xpStreakBonus,
  );

  /// Bonus for plan approved on first try.
  static const planApprovedBonus = RewardResult(
    coins: GameConstants.coinsPlanApprovedFirstTry,
    xp: 0,
  );
}
