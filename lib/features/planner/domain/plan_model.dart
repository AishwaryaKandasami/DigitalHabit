import 'package:cloud_firestore/cloud_firestore.dart';
import 'task_model.dart';

enum PlanStatus {
  draft,
  pendingApproval,
  approved,
  revisionRequested,
}

class PlanModel {
  final String id;
  final String memberId;
  final String weekStart; // ISO date string of Monday, e.g. "2026-04-13"
  final PlanStatus status;
  final String? parentNote;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final Map<String, List<TaskModel>> days; // "monday" -> [tasks]

  const PlanModel({
    required this.id,
    required this.memberId,
    required this.weekStart,
    required this.status,
    this.parentNote,
    this.submittedAt,
    this.reviewedAt,
    required this.days,
  });

  static const List<String> dayNames = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const List<String> dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  List<TaskModel> tasksForDay(String day) => days[day] ?? [];

  int get totalTasks =>
      days.values.fold(0, (sum, tasks) => sum + tasks.length);

  int get totalHealthyTasks => days.values.fold(
      0, (sum, tasks) => sum + tasks.where((t) => t.isHealthy).length);

  int get totalScreenTimeMinutes => days.values.fold(
      0,
      (sum, tasks) =>
          sum +
          tasks
              .where((t) => t.category.name == 'screenTime')
              .fold(0, (s, t) => s + t.duration));

  bool get isSubmittable =>
      status == PlanStatus.draft || status == PlanStatus.revisionRequested;

  bool get isEditable =>
      status == PlanStatus.draft || status == PlanStatus.revisionRequested;

  factory PlanModel.empty({
    required String memberId,
    required String weekStart,
  }) {
    return PlanModel(
      id: '',
      memberId: memberId,
      weekStart: weekStart,
      status: PlanStatus.draft,
      days: {for (final day in dayNames) day: []},
    );
  }

  Map<String, dynamic> toMap() => {
        'memberId': memberId,
        'weekStart': weekStart,
        'status': status.name,
        'parentNote': parentNote,
        'submittedAt':
            submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
        'reviewedAt':
            reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
        'days': days.map(
          (day, tasks) => MapEntry(day, tasks.map((t) => t.toMap()).toList()),
        ),
      };

  factory PlanModel.fromMap(String id, Map<String, dynamic> map) {
    final daysMap = map['days'] as Map<String, dynamic>? ?? {};
    final days = <String, List<TaskModel>>{};
    for (final entry in daysMap.entries) {
      final taskList = (entry.value as List<dynamic>?) ?? [];
      days[entry.key] = taskList
          .map((t) => TaskModel.fromMap(t as Map<String, dynamic>))
          .toList();
    }
    // Ensure all days exist
    for (final day in dayNames) {
      days.putIfAbsent(day, () => []);
    }

    return PlanModel(
      id: id,
      memberId: map['memberId'] as String,
      weekStart: map['weekStart'] as String,
      status: PlanStatus.values.byName(map['status'] as String),
      parentNote: map['parentNote'] as String?,
      submittedAt: map['submittedAt'] != null
          ? (map['submittedAt'] as Timestamp).toDate()
          : null,
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
      days: days,
    );
  }

  PlanModel copyWith({
    PlanStatus? status,
    String? parentNote,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    Map<String, List<TaskModel>>? days,
  }) {
    return PlanModel(
      id: id,
      memberId: memberId,
      weekStart: weekStart,
      status: status ?? this.status,
      parentNote: parentNote ?? this.parentNote,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      days: days ?? this.days,
    );
  }
}
