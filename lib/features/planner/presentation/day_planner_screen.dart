import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../domain/plan_model.dart';
import '../domain/task_model.dart';
import '../providers/planner_providers.dart';
import 'add_task_sheet.dart';

class DayPlannerScreen extends ConsumerWidget {
  final String dayName;

  const DayPlannerScreen({super.key, required this.dayName});

  String get _dayLabel {
    final idx = PlanModel.dayNames.indexOf(dayName);
    if (idx < 0) return dayName;
    return [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ][idx];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(draftPlanProvider);
    if (draft == null) {
      return const Scaffold(body: Center(child: Text('No plan loaded')));
    }

    final tasks = List<TaskModel>.from(draft.tasksForDay(dayName))
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    final isEditable = draft.isEditable;

    return Scaffold(
      appBar: AppBar(
        title: Text(_dayLabel),
        actions: [
          if (isEditable)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addTask(context, ref),
            ),
        ],
      ),
      body: tasks.isEmpty
          ? _EmptyDay(onAdd: isEditable ? () => _addTask(context, ref) : null)
          : _HourlyGrid(
              tasks: tasks,
              isEditable: isEditable,
              onTapTask: (task) => _editTask(context, ref, task),
              onDeleteTask: (task) => _deleteTask(ref, task),
              onAddAt: (hour, minute) =>
                  _addTask(context, ref, initialHour: hour, initialMinute: minute),
            ),
    );
  }

  Future<void> _addTask(
    BuildContext context,
    WidgetRef ref, {
    int initialHour = 8,
    int initialMinute = 0,
  }) async {
    final task = await showModalBottomSheet<TaskModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(
        initialHour: initialHour,
        initialMinute: initialMinute,
      ),
    );
    if (task == null) return;
    _updateDraftWithTask(ref, task);
  }

  Future<void> _editTask(
    BuildContext context,
    WidgetRef ref,
    TaskModel existing,
  ) async {
    final updated = await showModalBottomSheet<TaskModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(existingTask: existing),
    );
    if (updated == null) return;
    _replaceDraftTask(ref, existing.taskId, updated);
  }

  void _deleteTask(WidgetRef ref, TaskModel task) {
    final draft = ref.read(draftPlanProvider);
    if (draft == null) return;
    final dayTasks = List<TaskModel>.from(draft.tasksForDay(dayName))
      ..removeWhere((t) => t.taskId == task.taskId);
    final newDays = Map<String, List<TaskModel>>.from(draft.days);
    newDays[dayName] = dayTasks;
    ref.read(draftPlanProvider.notifier).set(draft.copyWith(days: newDays));
  }

  void _updateDraftWithTask(WidgetRef ref, TaskModel task) {
    final draft = ref.read(draftPlanProvider);
    if (draft == null) return;
    final dayTasks = List<TaskModel>.from(draft.tasksForDay(dayName))..add(task);
    final newDays = Map<String, List<TaskModel>>.from(draft.days);
    newDays[dayName] = dayTasks;
    ref.read(draftPlanProvider.notifier).set(draft.copyWith(days: newDays));
  }

  void _replaceDraftTask(WidgetRef ref, String taskId, TaskModel updated) {
    final draft = ref.read(draftPlanProvider);
    if (draft == null) return;
    final dayTasks = List<TaskModel>.from(draft.tasksForDay(dayName))
      ..removeWhere((t) => t.taskId == taskId)
      ..add(updated);
    final newDays = Map<String, List<TaskModel>>.from(draft.days);
    newDays[dayName] = dayTasks;
    ref.read(draftPlanProvider.notifier).set(draft.copyWith(days: newDays));
  }
}

class _EmptyDay extends StatelessWidget {
  final VoidCallback? onAdd;

  const _EmptyDay({this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wb_sunny_outlined,
              size: 64, color: AppColors.accent.withAlpha(120)),
          const SizedBox(height: 12),
          Text('Plan your day!', style: AppTextStyles.heading3),
          const SizedBox(height: 4),
          Text('Tap + to add activities', style: AppTextStyles.caption),
          if (onAdd != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add First Task'),
            ),
          ],
        ],
      ),
    );
  }
}

class _HourlyGrid extends StatelessWidget {
  final List<TaskModel> tasks;
  final bool isEditable;
  final void Function(TaskModel) onTapTask;
  final void Function(TaskModel) onDeleteTask;
  final void Function(int hour, int minute) onAddAt;

  const _HourlyGrid({
    required this.tasks,
    required this.isEditable,
    required this.onTapTask,
    required this.onDeleteTask,
    required this.onAddAt,
  });

  @override
  Widget build(BuildContext context) {
    // Bucket tasks by hour so each hour row shows its tasks sorted by minute.
    final tasksByHour = <int, List<TaskModel>>{};
    for (final task in tasks) {
      tasksByHour.putIfAbsent(task.hour, () => []).add(task);
    }
    // Sort each hour's tasks by minute
    for (final list in tasksByHour.values) {
      list.sort((a, b) => a.minute.compareTo(b.minute));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 17, // 6 AM to 10 PM
      itemBuilder: (context, index) {
        final hour = index + 6;
        final hourTasks = tasksByHour[hour] ?? const [];
        final timeStr = '${hour.toString().padLeft(2, '0')}:00';

        return Container(
          constraints: const BoxConstraints(minHeight: 60),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.surfaceVariant,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time column
              SizedBox(
                width: 60,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, left: 8),
                  child: Text(
                    timeStr,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: hourTasks.isNotEmpty
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              // Divider line
              Container(
                width: 2,
                constraints: const BoxConstraints(minHeight: 60),
                color: hourTasks.isNotEmpty
                    ? AppColors.primary.withAlpha(100)
                    : AppColors.surfaceVariant,
              ),
              // Task cards + add button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...hourTasks.map((task) => _TaskCard(
                          task: task,
                          isEditable: isEditable,
                          onTap: () => onTapTask(task),
                          onDelete: () => onDeleteTask(task),
                        )),
                    if (isEditable)
                      InkWell(
                        onTap: () => onAddAt(hour, 0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Icon(Icons.add,
                                  size: 16,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                hourTasks.isEmpty
                                    ? 'Tap to add at $timeStr'
                                    : 'Add another at this hour',
                                style: AppTextStyles.caption.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final bool isEditable;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.isEditable,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${task.hour.toString().padLeft(2, '0')}:${task.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: task.category.color.withAlpha(20),
        child: InkWell(
          onTap: isEditable ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(task.category.icon,
                    color: task.category.color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title, style: AppTextStyles.bodyBold),
                      Text(
                        '$timeStr  •  ${task.duration} min  •  ${task.categoryDisplayName}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                if (task.isHealthy)
                  const Icon(Icons.eco,
                      color: AppColors.accentGreen, size: 16)
                else
                  const Icon(Icons.phone_android,
                      color: AppColors.accentRed, size: 16),
                if (isEditable) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: onDelete,
                    child: const Icon(Icons.close,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
