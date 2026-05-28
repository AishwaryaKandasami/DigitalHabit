import 'package:cloud_firestore/cloud_firestore.dart';
import '../../planner/domain/task_category.dart';

/// Parent's qualitative feedback on a verified task.
enum ParentFeedback { positive, negative }

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
  final ParentFeedback? parentFeedback;
  final String? parentComment;
  /// True once the kid has seen the parent's review on this log.
  /// Used to drive the "new feedback" badge on the dashboard.
  final bool seenByChild;

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
    this.parentFeedback,
    this.parentComment,
    this.seenByChild = false,
  });

  bool get isPendingVerification => verifiedByParent == null;
  bool get isVerified => verifiedByParent == true;

  /// Has the parent reviewed it and the kid hasn't acknowledged yet?
  bool get hasUnreadFeedback => verifiedByParent != null && !seenByChild;

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
        'parentFeedback': parentFeedback?.name,
        'parentComment': parentComment,
        'seenByChild': seenByChild,
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
        parentFeedback: map['parentFeedback'] != null
            ? ParentFeedback.values.byName(map['parentFeedback'] as String)
            : null,
        parentComment: map['parentComment'] as String?,
        seenByChild: map['seenByChild'] as bool? ?? false,
      );
}
