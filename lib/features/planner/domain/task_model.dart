import '../../../core/utils/id_generator.dart';
import 'task_category.dart';

class TaskModel {
  final String taskId;
  final int hour; // 0-23
  final int duration; // minutes
  final String title;
  final TaskCategory category;
  final bool isDigitalActivity;
  final bool isHealthy;

  const TaskModel({
    required this.taskId,
    required this.hour,
    required this.duration,
    required this.title,
    required this.category,
    required this.isDigitalActivity,
    required this.isHealthy,
  });

  factory TaskModel.create({
    required int hour,
    required int duration,
    required String title,
    required TaskCategory category,
  }) {
    final isDigital = category == TaskCategory.screenTime;
    return TaskModel(
      taskId: IdGenerator.uuid(),
      hour: hour,
      duration: duration,
      title: title,
      category: category,
      isDigitalActivity: isDigital,
      isHealthy: category.isHealthyByDefault,
    );
  }

  Map<String, dynamic> toMap() => {
        'taskId': taskId,
        'hour': hour,
        'duration': duration,
        'title': title,
        'category': category.name,
        'isDigitalActivity': isDigitalActivity,
        'isHealthy': isHealthy,
      };

  factory TaskModel.fromMap(Map<String, dynamic> map) => TaskModel(
        taskId: map['taskId'] as String,
        hour: map['hour'] as int,
        duration: map['duration'] as int,
        title: map['title'] as String,
        category: TaskCategory.values.byName(map['category'] as String),
        isDigitalActivity: map['isDigitalActivity'] as bool,
        isHealthy: map['isHealthy'] as bool,
      );

  TaskModel copyWith({
    int? hour,
    int? duration,
    String? title,
    TaskCategory? category,
  }) {
    final cat = category ?? this.category;
    return TaskModel(
      taskId: taskId,
      hour: hour ?? this.hour,
      duration: duration ?? this.duration,
      title: title ?? this.title,
      category: cat,
      isDigitalActivity: cat == TaskCategory.screenTime,
      isHealthy: cat.isHealthyByDefault,
    );
  }
}
