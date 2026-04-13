import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../domain/task_log_model.dart';
import '../domain/reward_calculator.dart';
import '../../planner/domain/task_model.dart';
import '../../shop/domain/transaction_model.dart';

class TaskLogRepository {
  final FirebaseFirestore _firestore;

  TaskLogRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Complete a task: create log, earn coins/XP, update wallet.
  Future<TaskLogModel> completeTask({
    required String familyId,
    required String memberId,
    required String planId,
    required String date,
    required TaskModel task,
  }) async {
    final reward = RewardCalculator.forTaskCompletion(isHealthy: task.isHealthy);

    // Create task log
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

    // Run as batch: create log + update wallet + create transaction
    final batch = _firestore.batch();

    // 1. Task log
    batch.set(logRef, log.toMap());

    // 2. Update wallet (increment coins)
    final memberRef = _firestore
        .collection(FirestorePaths.members(familyId))
        .doc(memberId);
    batch.update(memberRef, {
      'wallet.coins': FieldValue.increment(reward.coins),
      'wallet.totalEarned': FieldValue.increment(reward.coins),
    });

    // 3. Transaction record
    final txRef =
        _firestore.collection(FirestorePaths.transactions(familyId)).doc();
    final tx = TransactionModel(
      id: txRef.id,
      memberId: memberId,
      type: TransactionType.earn,
      amount: reward.coins,
      reason: 'Completed: ${task.title}',
      createdAt: DateTime.now(),
    );
    batch.set(txRef, tx.toMap());

    await batch.commit();
    return log;
  }

  /// Parent verifies a completed task — awards bonus coins/XP.
  Future<void> verifyTask({
    required String familyId,
    required String memberId,
    required TaskLogModel log,
    required bool approved,
  }) async {
    final batch = _firestore.batch();

    // Update the log
    final logRef = _firestore
        .collection(FirestorePaths.taskLogs(familyId))
        .doc(log.id);
    batch.update(logRef, {'verifiedByParent': approved});

    if (approved) {
      final bonus = RewardCalculator.verificationBonus;

      // Bonus coins
      final memberRef = _firestore
          .collection(FirestorePaths.members(familyId))
          .doc(memberId);
      batch.update(memberRef, {
        'wallet.coins': FieldValue.increment(bonus.coins),
        'wallet.totalEarned': FieldValue.increment(bonus.coins),
      });

      // Transaction
      final txRef =
          _firestore.collection(FirestorePaths.transactions(familyId)).doc();
      batch.set(txRef, TransactionModel(
        id: txRef.id,
        memberId: memberId,
        type: TransactionType.earn,
        amount: bonus.coins,
        reason: 'Parent verified: ${log.title}',
        createdAt: DateTime.now(),
      ).toMap());
    }

    await batch.commit();
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
