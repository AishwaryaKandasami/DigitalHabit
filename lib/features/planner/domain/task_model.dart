import '../../../core/utils/id_generator.dart';
import 'task_category.dart';

class TaskModel {
  final String taskId;
  final int hour; // 0-23
  final int minute; // 0, 15, 30, 45
  final int duration; // minutes
  final String title;
  final TaskCategory category;
  final String? customCategoryName; // when category == custom
  final bool isDigitalActivity;
  final bool isHealthy;

  const TaskModel({
    required this.taskId,
    required this.hour,
    this.minute = 0,
    required this.duration,
    required this.title,
    required this.category,
    this.customCategoryName,
    required this.isDigitalActivity,
    required this.isHealthy,
  });

  /// Start time in minutes since midnight (for sorting).
  int get startMinutes => hour * 60 + minute;

  /// Display name: shows custom name if set, else the category default.
  String get categoryDisplayName =>
      (category == TaskCategory.custom &&
              customCategoryName != null &&
              customCategoryName!.isNotEmpty)
          ? customCategoryName!
          : category.displayName;

  factory TaskModel.create({
    required int hour,
    int minute = 0,
    required int duration,
    required String title,
    required TaskCategory category,
    String? customCategoryName,
  }) {
    final isDigital = category == TaskCategory.screenTime;
    return TaskModel(
      taskId: IdGenerator.uuid(),
      hour: hour,
      minute: minute,
      duration: duration,
      title: title,
      category: category,
      customCategoryName: customCategoryName,
      isDigitalActivity: isDigital,
      isHealthy: category.isHealthyByDefault,
    );
  }

  Map<String, dynamic> toMap() => {
        'taskId': taskId,
        'hour': hour,
        'minute': minute,
        'duration': duration,
        'title': title,
        'category': category.name,
        'customCategoryName': customCategoryName,
        'isDigitalActivity': isDigitalActivity,
        'isHealthy': isHealthy,
      };

  factory TaskModel.fromMap(Map<String, dynamic> map) => TaskModel(
        taskId: map['taskId'] as String,
        hour: map['hour'] as int,
        minute: map['minute'] as int? ?? 0,
        duration: map['duration'] as int,
        title: map['title'] as String,
        category: TaskCategory.values.byName(map['category'] as String),
        customCategoryName: map['customCategoryName'] as String?,
        isDigitalActivity: map['isDigitalActivity'] as bool,
        isHealthy: map['isHealthy'] as bool,
      );

  TaskModel copyWith({
    int? hour,
    int? minute,
    int? duration,
    String? title,
    TaskCategory? category,
    String? customCategoryName,
  }) {
    final cat = category ?? this.category;
    return TaskModel(
      taskId: taskId,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      duration: duration ?? this.duration,
      title: title ?? this.title,
      category: cat,
      customCategoryName: customCategoryName ?? this.customCategoryName,
      isDigitalActivity: cat == TaskCategory.screenTime,
      isHealthy: cat.isHealthyByDefault,
    );
  }
}
