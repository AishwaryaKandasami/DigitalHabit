class GameConstants {
  GameConstants._();

  // --- Evolution XP Thresholds (cumulative) ---
  static const List<int> evolutionXpThresholds = [0, 100, 500, 1500, 4000];
  static const List<String> evolutionStageNames = [
    'Baby',
    'Young',
    'Teen',
    'Adult',
    'Legendary',
  ];

  // --- XP Rewards ---
  static const int xpHealthyTask = 15;
  static const int xpAnyTask = 5;
  static const int xpFullDayBonus = 25;
  static const int xpStreakBonus = 50; // 7-day streak
  static const int xpParentVerifiedBonus = 5;

  // --- Coin Rewards ---
  static const int coinsAnyTask = 10;
  static const int coinsHealthyTask = 15;
  static const int coinsFullDayBonus = 30;
  static const int coinsFullWeekBonus = 100;
  static const int coinsStreakBonus = 50;
  static const int coinsPlanApprovedFirstTry = 20;

  // --- Mood System ---
  // Tone: all-positive. Tasks and neglect never subtract mood; the creature
  // only ever cheers up. Penalties are kept as named zeros so existing call
  // sites stay valid and the intent is explicit.
  static const int moodMax = 100;
  static const int moodHealthyTask = 5;
  static const int moodUnhealthyTask = 0; // never penalize screen time
  static const int moodSkippedTask = 0; // never penalize a missed task
  static const int moodDailyDecay = 0; // no guilt for not opening the app
  static const int moodFoodItem = 15;
  static const int moodParentPraise = 10;
  static const int moodParentCritique = 0; // "needs work" never drops mood

  // --- Parent feedback on verified tasks ---
  /// Coins deducted when a verified task is marked "needs improvement".
  /// All-positive tone: no deduction.
  static const int coinsParentCritiquePenalty = 0;

  // Mood thresholds
  static const int moodHappyThreshold = 80;
  static const int moodNeutralThreshold = 50;
  static const int moodSadThreshold = 25;
  // Below 25 = sick

  // --- Health System ---
  static const int healthMax = 100;
  static const int healthRegenPerDay = 5; // when >70% healthy tasks
  static const int healthDropPerDay = -10; // when <40% healthy tasks
  static const int healthSickThreshold = 30;
  static const int healthPotionRestore = 25;

  // --- Health Ratio Thresholds ---
  static const double healthyRatioGood = 0.7;
  static const double healthyRatioBad = 0.4;

  // --- Streak ---
  static const int streakBonusDays = 7;

  // --- Screen Time ---
  static const int defaultMaxScreenTimeMinutes = 120; // 2 hours

  // --- Invite Code ---
  static const int inviteCodeLength = 6;
}
