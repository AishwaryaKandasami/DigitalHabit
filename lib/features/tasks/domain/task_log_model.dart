import 'package:cloud_firestore/cloud_firestore.dart';
import '../../planner/domain/task_category.dart';

/// A record that a child completed a planned task. Rewards are granted on
/// completion — there is no parent verification step in the single-login model.
class TaskLogModel {
  final String id;
  final String planId;
  final String memberId;
  final String date; // ISO date string "2026-04-13"
  final String taskId;
  final String title;
  final TaskCategory category;
  final bool isHealthy;
  final DateTime completedAt;
  final bool completedByChild;
  final int coinsEarned;
  final int xpEarned;

  const TaskLogModel({
    required this.id,
    required this.planId,
    required this.memberId,
    required this.date,
    required this.taskId,
    required this.title,
    required this.category,
    required this.isHealthy,
    required this.completedAt,
    this.completedByChild = true,
    required this.coinsEarned,
    required this.xpEarned,
  });

  Map<String, dynamic> toMap() => {
        'planId': planId,
        'memberId': memberId,
        'date': date,
        'taskId': taskId,
        'title': title,
        'category': category.name,
        'isHealthy': isHealthy,
        'completedAt': Timestamp.fromDate(completedAt),
        'completedByChild': completedByChild,
        'coinsEarned': coinsEarned,
        'xpEarned': xpEarned,
      };

  factory TaskLogModel.fromMap(String id, Map<String, dynamic> map) =>
      TaskLogModel(
        id: id,
        planId: map['planId'] as String,
        memberId: map['memberId'] as String,
        date: map['date'] as String,
        taskId: map['taskId'] as String,
        title: map['title'] as String,
        category: TaskCategory.values.byName(map['category'] as String),
        isHealthy: map['isHealthy'] as bool,
        completedAt: (map['completedAt'] as Timestamp).toDate(),
        completedByChild: map['completedByChild'] as bool? ?? true,
        coinsEarned: map['coinsEarned'] as int? ?? 0,
        xpEarned: map['xpEarned'] as int? ?? 0,
      );
}
