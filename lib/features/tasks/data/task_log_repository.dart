import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/constants/game_constants.dart';
import '../domain/task_log_model.dart';
import '../domain/reward_calculator.dart';
import '../../planner/domain/task_model.dart';
import '../../shop/domain/transaction_model.dart';
import '../../avatar/domain/avatar_state.dart';
import '../../avatar/domain/evolution_calculator.dart';
import '../../family/domain/member_model.dart';

/// Result of completing a task, includes whether the avatar leveled up.
class TaskCompletionResult {
  final TaskLogModel log;
  final bool leveledUp;
  final int previousStage;
  final int newStage;

  const TaskCompletionResult({
    required this.log,
    this.leveledUp = false,
    this.previousStage = 1,
    this.newStage = 1,
  });
}

class TaskLogRepository {
  final FirebaseFirestore _firestore;

  TaskLogRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Complete a task: create log, earn coins/XP, update wallet + avatar.
  /// Uses a transaction to read current member state, compute new avatar, write atomically.
  Future<TaskCompletionResult> completeTask({
    required String familyId,
    required String memberId,
    required String planId,
    required String date,
    required TaskModel task,
  }) async {
    final reward = RewardCalculator.forTaskCompletion(isHealthy: task.isHealthy);

    final logRef =
        _firestore.collection(FirestorePaths.taskLogs(familyId)).doc();
    final log = TaskLogModel(
      id: logRef.id,
      planId: planId,
      memberId: memberId,
      date: date,
      taskId: task.taskId,
      title: task.title,
      category: task.category,
      isHealthy: task.isHealthy,
      completedAt: DateTime.now(),
      coinsEarned: reward.coins,
      xpEarned: reward.xp,
    );

    final memberRef = _firestore
        .collection(FirestorePaths.members(familyId))
        .doc(memberId);
    final txRef =
        _firestore.collection(FirestorePaths.transactions(familyId)).doc();

    bool leveledUp = false;
    int previousStage = 1;
    int newStage = 1;

    await _firestore.runTransaction((txn) async {
      // Read current member to get avatar state
      final memberSnap = await txn.get(memberRef);
      final member = MemberModel.fromMap(memberSnap.id, memberSnap.data()!);

      previousStage = member.avatarState.evolutionStage;

      // Apply XP gain
      AvatarState updatedAvatar =
          EvolutionCalculator.addXp(member.avatarState, reward.xp);

      // Apply mood change based on task health
      final moodDelta = task.isHealthy
          ? GameConstants.moodHealthyTask
          : GameConstants.moodUnhealthyTask;
      updatedAvatar = EvolutionCalculator.applyMoodChange(updatedAvatar, moodDelta);

      newStage = updatedAvatar.evolutionStage;
      leveledUp = newStage > previousStage;

      // Update last active date for streak tracking
      final todayStr = date;

      // 1. Task log
      txn.set(logRef, log.toMap());

      // 2. Update member: wallet + avatar + lastActiveDate
      txn.update(memberRef, {
        'wallet.coins': FieldValue.increment(reward.coins),
        'wallet.totalEarned': FieldValue.increment(reward.coins),
        'avatarState': updatedAvatar.toMap(),
        'lastActiveDate': todayStr,
      });

      // 3. Transaction record
      txn.set(txRef, TransactionModel(
        id: txRef.id,
        memberId: memberId,
        type: TransactionType.earn,
        amount: reward.coins,
        reason: 'Completed: ${task.title}',
        createdAt: DateTime.now(),
      ).toMap());
    });

    return TaskCompletionResult(
      log: log,
      leveledUp: leveledUp,
      previousStage: previousStage,
      newStage: newStage,
    );
  }

  /// Parent verifies a completed task — awards bonus coins/XP + avatar XP.
  Future<void> verifyTask({
    required String familyId,
    required String memberId,
    required TaskLogModel log,
    required bool approved,
  }) async {
    final logRef = _firestore
        .collection(FirestorePaths.taskLogs(familyId))
        .doc(log.id);

    if (!approved) {
      // Simple update — no rewards
      await logRef.update({'verifiedByParent': false});
      return;
    }

    final bonus = RewardCalculator.verificationBonus;
    final memberRef = _firestore
        .collection(FirestorePaths.members(familyId))
        .doc(memberId);
    final txRef =
        _firestore.collection(FirestorePaths.transactions(familyId)).doc();

    await _firestore.runTransaction((txn) async {
      final memberSnap = await txn.get(memberRef);
      final member = MemberModel.fromMap(memberSnap.id, memberSnap.data()!);

      // Apply bonus XP to avatar
      final updatedAvatar =
          EvolutionCalculator.addXp(member.avatarState, bonus.xp);

      txn.update(logRef, {'verifiedByParent': true});

      txn.update(memberRef, {
        'wallet.coins': FieldValue.increment(bonus.coins),
        'wallet.totalEarned': FieldValue.increment(bonus.coins),
        'avatarState': updatedAvatar.toMap(),
      });

      txn.set(txRef, TransactionModel(
        id: txRef.id,
        memberId: memberId,
        type: TransactionType.earn,
        amount: bonus.coins,
        reason: 'Parent verified: ${log.title}',
        createdAt: DateTime.now(),
      ).toMap());
    });
  }

  /// Apply daily mood decay retroactively based on last active date.
  Future<void> applyMoodDecay({
    required String familyId,
    required String memberId,
  }) async {
    final memberRef = _firestore
        .collection(FirestorePaths.members(familyId))
        .doc(memberId);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(memberRef);
      final member = MemberModel.fromMap(snap.id, snap.data()!);

      final lastActive = member.lastActiveDate;
      if (lastActive == null) return;

      final lastDate = DateTime.parse(lastActive);
      final today = DateTime.now();
      final daysMissed = DateTime(today.year, today.month, today.day)
              .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
              .inDays -
          1; // subtract 1 because the last active day itself doesn't decay

      if (daysMissed <= 0) return;

      final updatedAvatar =
          EvolutionCalculator.applyMoodDecay(member.avatarState, daysMissed);

      txn.update(memberRef, {
        'avatarState': updatedAvatar.toMap(),
      });
    });
  }

  /// Update streak: call after task completion to check/increment streak.
  Future<RewardResult?> updateStreak({
    required String familyId,
    required String memberId,
    required String todayDate,
  }) async {
    final memberRef = _firestore
        .collection(FirestorePaths.members(familyId))
        .doc(memberId);

    RewardResult? streakReward;

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(memberRef);
      final member = MemberModel.fromMap(snap.id, snap.data()!);

      final lastActive = member.lastActiveDate;
      final today = DateTime.parse(todayDate);

      int newStreak = member.streakDays;

      if (lastActive != null) {
        final lastDate = DateTime.parse(lastActive);
        final diff = DateTime(today.year, today.month, today.day)
            .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
            .inDays;

        if (diff == 1) {
          // Consecutive day — increment streak
          newStreak += 1;
        } else if (diff > 1) {
          // Streak broken
          newStreak = 1;
        }
        // diff == 0 means same day, don't change streak
      } else {
        newStreak = 1;
      }

      final updates = <String, dynamic>{
        'streakDays': newStreak,
      };

      // Award streak bonus at every 7-day milestone
      if (newStreak > 0 &&
          newStreak % GameConstants.streakBonusDays == 0 &&
          newStreak != member.streakDays) {
        final bonus = RewardCalculator.streakBonus;
        streakReward = bonus;

        final updatedAvatar =
            EvolutionCalculator.addXp(member.avatarState, bonus.xp);
        updates['wallet.coins'] = FieldValue.increment(bonus.coins);
        updates['wallet.totalEarned'] = FieldValue.increment(bonus.coins);
        updates['avatarState'] = updatedAvatar.toMap();

        // Also create a transaction for the streak bonus
        final txRef = _firestore
            .collection(FirestorePaths.transactions(familyId))
            .doc();
        txn.set(txRef, TransactionModel(
          id: txRef.id,
          memberId: memberId,
          type: TransactionType.earn,
          amount: bonus.coins,
          reason: '$newStreak-day streak bonus!',
          createdAt: DateTime.now(),
        ).toMap());
      }

      txn.update(memberRef, updates);
    });

    return streakReward;
  }

  /// Check for full day completion bonus and apply it.
  Future<RewardResult?> checkFullDayBonus({
    required String familyId,
    required String memberId,
    required String date,
    required int totalTasksToday,
  }) async {
    // Count completed tasks for today
    final logsSnap = await _firestore
        .collection(FirestorePaths.taskLogs(familyId))
        .where('memberId', isEqualTo: memberId)
        .where('date', isEqualTo: date)
        .get();

    if (logsSnap.docs.length < totalTasksToday || totalTasksToday == 0) {
      return null;
    }

    // All tasks done! Award full day bonus
    final bonus = RewardCalculator.fullDayBonus;
    final memberRef = _firestore
        .collection(FirestorePaths.members(familyId))
        .doc(memberId);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(memberRef);
      final member = MemberModel.fromMap(snap.id, snap.data()!);
      final updatedAvatar =
          EvolutionCalculator.addXp(member.avatarState, bonus.xp);

      txn.update(memberRef, {
        'wallet.coins': FieldValue.increment(bonus.coins),
        'wallet.totalEarned': FieldValue.increment(bonus.coins),
        'avatarState': updatedAvatar.toMap(),
      });

      final txRef = _firestore
          .collection(FirestorePaths.transactions(familyId))
          .doc();
      txn.set(txRef, TransactionModel(
        id: txRef.id,
        memberId: memberId,
        type: TransactionType.earn,
        amount: bonus.coins,
        reason: 'All tasks completed for $date!',
        createdAt: DateTime.now(),
      ).toMap());
    });

    return bonus;
  }

  /// Get all task logs for a member on a specific date.
  Stream<List<TaskLogModel>> streamLogsForDate(
    String familyId,
    String memberId,
    String date,
  ) {
    return _firestore
        .collection(FirestorePaths.taskLogs(familyId))
        .where('memberId', isEqualTo: memberId)
        .where('date', isEqualTo: date)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TaskLogModel.fromMap(d.id, d.data())).toList());
  }

  /// Stream all pending verification logs for the family (parent view).
  Stream<List<TaskLogModel>> streamPendingVerification(String familyId) {
    return _firestore
        .collection(FirestorePaths.taskLogs(familyId))
        .where('verifiedByParent', isNull: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TaskLogModel.fromMap(d.id, d.data())).toList());
  }

  /// Check if a specific task has been completed today.
  Future<bool> isTaskCompleted(
    String familyId,
    String memberId,
    String date,
    String taskId,
  ) async {
    final query = await _firestore
        .collection(FirestorePaths.taskLogs(familyId))
        .where('memberId', isEqualTo: memberId)
        .where('date', isEqualTo: date)
        .where('taskId', isEqualTo: taskId)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }
}
