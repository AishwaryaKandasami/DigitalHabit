import 'package:cloud_firestore/cloud_firestore.dart';
import '../../planner/domain/task_category.dart';

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
  final bool? verifiedByParent; // null = not yet reviewed
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
    this.verifiedByParent,
    required this.coinsEarned,
    required this.xpEarned,
  });

  bool get isPendingVerification => verifiedByParent == null;
  bool get isVerified => verifiedByParent == true;

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
        'verifiedByParent': verifiedByParent,
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
        verifiedByParent: map['verifiedByParent'] as bool?,
        coinsEarned: map['coinsEarned'] as int? ?? 0,
        xpEarned: map['xpEarned'] as int? ?? 0,
      );
}
