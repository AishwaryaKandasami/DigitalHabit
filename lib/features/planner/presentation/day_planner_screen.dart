import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/id_generator.dart';
import '../domain/plan_model.dart';
import '../domain/task_model.dart';
import '../providers/planner_providers.dart';
import '../../auth/providers/auth_providers.dart';
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
    // Per-day: today & future stay editable even after approval.
    final isEditable = draft.isDayEditable(dayName);

    return Scaffold(
      appBar: AppBar(
        title: Text(_dayLabel),
        actions: [
          if (isEditable) ...[
            IconButton(
              icon: const Icon(Icons.content_copy),
              tooltip: 'Copy tasks from another day',
              onPressed: () => _copyFromAnotherDay(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add task',
              onPressed: () => _addTask(context, ref),
            ),
          ],
        ],
      ),
      body: tasks.isEmpty
          ? _EmptyDay(onAdd: isEditable ? () => _addTask(context, ref) : null)
          : _DayTimeline(
              tasks: tasks,
              isEditable: isEditable,
              onTapTask: (task) => _editTask(context, ref, task),
              onDeleteTask: (task) =>
                  _deleteTaskWithPrompt(context, ref, task),
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
    if (!context.mounted) return;
    _promptApplyToOtherDays(
      context,
      ref,
      'Added "${task.title}".',
      onApply: () => _propagateAdd(ref, task),
    );
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
    if (!context.mounted) return;
    _promptApplyToOtherDays(
      context,
      ref,
      'Updated "${updated.title}".',
      onApply: () => _propagateEdit(ref, original: existing, updated: updated),
    );
  }

  void _deleteTask(WidgetRef ref, TaskModel task) {
    final draft = ref.read(draftPlanProvider);
    if (draft == null) return;
    final dayTasks = List<TaskModel>.from(draft.tasksForDay(dayName))
      ..removeWhere((t) => t.taskId == task.taskId);
    final newDays = Map<String, List<TaskModel>>.from(draft.days);
    newDays[dayName] = dayTasks;
    _commitDraft(ref, draft.copyWith(days: newDays));
  }

  /// Called from the hourly grid after a long-press / close-icon delete.
  /// Same signature as _deleteTask but also surfaces the apply-to-others prompt.
  void _deleteTaskWithPrompt(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
  ) {
    _deleteTask(ref, task);
    _promptApplyToOtherDays(
      context,
      ref,
      'Removed "${task.title}".',
      onApply: () => _propagateDelete(ref, task),
    );
  }

  // ---------------------------------------------------------------
  // Apply-to-other-days propagation
  // ---------------------------------------------------------------

  /// Identifies a "same" task across days by title + start time.
  bool _matches(TaskModel a, TaskModel b) =>
      a.title == b.title && a.hour == b.hour && a.minute == b.minute;

  /// Update the in-memory draft AND persist it immediately. There's no submit
  /// / approval step — plans are active as soon as they're edited. A brand-new
  /// plan (empty id) is created on first save; we then adopt the returned id so
  /// later edits patch the same doc.
  Future<void> _commitDraft(WidgetRef ref, PlanModel newPlan) async {
    ref.read(draftPlanProvider.notifier).set(newPlan);
    final appUser = ref.read(appUserProvider).value;
    final familyId = appUser?.familyId;
    if (familyId == null) return;
    try {
      final saved =
          await ref.read(planRepositoryProvider).savePlan(familyId, newPlan);
      if (saved.id != newPlan.id) {
        ref.read(draftPlanProvider.notifier).set(saved);
      }
    } catch (_) {
      // best-effort; the in-memory draft already reflects the change
    }
  }

  /// Show a snackbar after an add/edit/delete with TWO explicit choices:
  /// keep the change local to this day, or apply it to every day in the
  /// week. The kid actively picks instead of having to know that ignoring
  /// the snackbar means "just this day".
  void _promptApplyToOtherDays(
    BuildContext context,
    WidgetRef ref,
    String summary, {
    required VoidCallback onApply,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(summary, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 2),
            const Text(
              'Just today, or every day this week?',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => messenger.removeCurrentSnackBar(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Just today'),
                ),
                const SizedBox(width: 4),
                FilledButton.icon(
                  onPressed: () {
                    // Snapshot the draft BEFORE propagation so the kid can
                    // undo the cross-day spread if they tapped by mistake.
                    final snapshot = ref.read(draftPlanProvider);
                    onApply();
                    messenger.removeCurrentSnackBar();
                    messenger.showSnackBar(
                      SnackBar(
                        content: const Text('Updated all days this week.'),
                        duration: const Duration(seconds: 5),
                        action: snapshot == null
                            ? null
                            : SnackBarAction(
                                label: 'Undo',
                                onPressed: () {
                                  _commitDraft(ref, snapshot);
                                  messenger.removeCurrentSnackBar();
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Reverted to just this day.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.repeat, size: 16),
                  label: const Text('All days'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Copy a newly-added task into every other day in the week. Skips days
  /// that already have a matching (title, time) task to avoid duplicates.
  void _propagateAdd(WidgetRef ref, TaskModel added) {
    final draft = ref.read(draftPlanProvider);
    if (draft == null) return;
    final newDays = Map<String, List<TaskModel>>.from(draft.days);
    for (final d in PlanModel.dayNames) {
      if (d == dayName) continue;
      if (!draft.isDayEditable(d)) continue; // don't touch locked past days
      final tasks = List<TaskModel>.from(draft.tasksForDay(d));
      if (tasks.any((t) => _matches(t, added))) continue;
      tasks.add(TaskModel(
        taskId: IdGenerator.uuid(),
        hour: added.hour,
        minute: added.minute,
        duration: added.duration,
        title: added.title,
        category: added.category,
        customCategoryName: added.customCategoryName,
        isDigitalActivity: added.isDigitalActivity,
        isHealthy: added.isHealthy,
      ));
      newDays[d] = tasks;
    }
    _commitDraft(ref, draft.copyWith(days: newDays));
  }

  /// On every other day, find the task that matched the ORIGINAL (title, time)
  /// and update its fields to the new title/time/duration/category. If a day
  /// has no matching task, add a fresh copy of the updated task there.
  void _propagateEdit(
    WidgetRef ref, {
    required TaskModel original,
    required TaskModel updated,
  }) {
    final draft = ref.read(draftPlanProvider);
    if (draft == null) return;
    final newDays = Map<String, List<TaskModel>>.from(draft.days);
    for (final d in PlanModel.dayNames) {
      if (d == dayName) continue;
      if (!draft.isDayEditable(d)) continue; // don't touch locked past days
      final tasks = List<TaskModel>.from(draft.tasksForDay(d));
      final idx = tasks.indexWhere((t) => _matches(t, original));
      if (idx >= 0) {
        tasks[idx] = TaskModel(
          taskId: tasks[idx].taskId, // keep id stable on edit
          hour: updated.hour,
          minute: updated.minute,
          duration: updated.duration,
          title: updated.title,
          category: updated.category,
          customCategoryName: updated.customCategoryName,
          isDigitalActivity: updated.isDigitalActivity,
          isHealthy: updated.isHealthy,
        );
      } else if (!tasks.any((t) => _matches(t, updated))) {
        // No original to update AND no duplicate of the new one — add fresh.
        tasks.add(TaskModel(
          taskId: IdGenerator.uuid(),
          hour: updated.hour,
          minute: updated.minute,
          duration: updated.duration,
          title: updated.title,
          category: updated.category,
          customCategoryName: updated.customCategoryName,
          isDigitalActivity: updated.isDigitalActivity,
          isHealthy: updated.isHealthy,
        ));
      }
      newDays[d] = tasks;
    }
    _commitDraft(ref, draft.copyWith(days: newDays));
  }

  /// Remove tasks that match (title, time) on every other day.
  void _propagateDelete(WidgetRef ref, TaskModel removed) {
    final draft = ref.read(draftPlanProvider);
    if (draft == null) return;
    final newDays = Map<String, List<TaskModel>>.from(draft.days);
    for (final d in PlanModel.dayNames) {
      if (d == dayName) continue;
      if (!draft.isDayEditable(d)) continue; // don't touch locked past days
      final tasks = List<TaskModel>.from(draft.tasksForDay(d))
        ..removeWhere((t) => _matches(t, removed));
      newDays[d] = tasks;
    }
    _commitDraft(ref, draft.copyWith(days: newDays));
  }

  void _updateDraftWithTask(WidgetRef ref, TaskModel task) {
    final draft = ref.read(draftPlanProvider);
    if (draft == null) return;
    final dayTasks = List<TaskModel>.from(draft.tasksForDay(dayName))..add(task);
    final newDays = Map<String, List<TaskModel>>.from(draft.days);
    newDays[dayName] = dayTasks;
    _commitDraft(ref, draft.copyWith(days: newDays));
  }

  void _replaceDraftTask(WidgetRef ref, String taskId, TaskModel updated) {
    final draft = ref.read(draftPlanProvider);
    if (draft == null) return;
    final dayTasks = List<TaskModel>.from(draft.tasksForDay(dayName))
      ..removeWhere((t) => t.taskId == taskId)
      ..add(updated);
    final newDays = Map<String, List<TaskModel>>.from(draft.days);
    newDays[dayName] = dayTasks;
    _commitDraft(ref, draft.copyWith(days: newDays));
  }

  Future<void> _copyFromAnotherDay(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final draft = ref.read(draftPlanProvider);
    if (draft == null) return;

    // Build the picker entries: every day except the current one,
    // with its task count.
    final entries = <_CopySource>[];
    for (int i = 0; i < PlanModel.dayNames.length; i++) {
      final src = PlanModel.dayNames[i];
      if (src == dayName) continue;
      final tasks = draft.tasksForDay(src);
      entries.add(_CopySource(
        dayName: src,
        label: [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ][i],
        taskCount: tasks.length,
      ));
    }

    final hasAny = entries.any((e) => e.taskCount > 0);
    if (!hasAny) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No other day has tasks to copy yet. Plan another day first!',
          ),
        ),
      );
      return;
    }

    final picked = await showDialog<_CopyPickResult>(
      context: context,
      builder: (_) => _CopyFromDayDialog(
        sources: entries,
        targetLabel: _dayLabel,
        hasExistingTasks: draft.tasksForDay(dayName).isNotEmpty,
      ),
    );
    if (picked == null) return;

    final sourceTasks = draft.tasksForDay(picked.sourceDay);
    if (sourceTasks.isEmpty) return;

    // Fresh IDs so each copy is an independent task (delete / edit doesn't
    // touch the source day).
    final copies = sourceTasks
        .map((t) => TaskModel(
              taskId: IdGenerator.uuid(),
              hour: t.hour,
              minute: t.minute,
              duration: t.duration,
              title: t.title,
              category: t.category,
              customCategoryName: t.customCategoryName,
              isDigitalActivity: t.isDigitalActivity,
              isHealthy: t.isHealthy,
            ))
        .toList();

    final existing = List<TaskModel>.from(draft.tasksForDay(dayName));
    final merged = picked.replace ? copies : [...existing, ...copies];

    final newDays = Map<String, List<TaskModel>>.from(draft.days);
    newDays[dayName] = merged;
    _commitDraft(ref, draft.copyWith(days: newDays));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(picked.replace
              ? 'Replaced $_dayLabel with ${copies.length} tasks from ${picked.sourceLabel}.'
              : 'Added ${copies.length} tasks from ${picked.sourceLabel}.'),
        ),
      );
    }
  }
}

class _CopySource {
  final String dayName;
  final String label;
  final int taskCount;
  const _CopySource({
    required this.dayName,
    required this.label,
    required this.taskCount,
  });
}

class _CopyPickResult {
  final String sourceDay;
  final String sourceLabel;
  final bool replace;
  const _CopyPickResult({
    required this.sourceDay,
    required this.sourceLabel,
    required this.replace,
  });
}

class _CopyFromDayDialog extends StatefulWidget {
  final List<_CopySource> sources;
  final String targetLabel;
  final bool hasExistingTasks;

  const _CopyFromDayDialog({
    required this.sources,
    required this.targetLabel,
    required this.hasExistingTasks,
  });

  @override
  State<_CopyFromDayDialog> createState() => _CopyFromDayDialogState();
}

class _CopyFromDayDialogState extends State<_CopyFromDayDialog> {
  String? _selectedDay;
  // Default to append (safer): existing tasks aren't wiped out.
  bool _replace = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Copy to ${widget.targetLabel}'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pick a day to copy tasks from:',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 8),
              ...widget.sources.map((s) {
                final enabled = s.taskCount > 0;
                final selected = _selectedDay == s.dayName;
                return ListTile(
                  dense: true,
                  enabled: enabled,
                  onTap: enabled
                      ? () => setState(() => _selectedDay = s.dayName)
                      : null,
                  leading: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected
                        ? AppColors.primary
                        : (enabled
                            ? AppColors.textSecondary
                            : AppColors.textSecondary.withAlpha(80)),
                  ),
                  title: Text(
                    s.label,
                    style: TextStyle(
                      color: enabled
                          ? (selected
                              ? AppColors.primary
                              : AppColors.textPrimary)
                          : AppColors.textSecondary,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    s.taskCount == 0
                        ? 'No tasks'
                        : '${s.taskCount} task${s.taskCount == 1 ? '' : 's'}',
                    style: AppTextStyles.caption,
                  ),
                );
              }),
              if (widget.hasExistingTasks) ...[
                const Divider(height: 24),
                Text(
                  '${widget.targetLabel} already has tasks. What should we do?',
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.add),
                      label: Text('Add'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.swap_horiz),
                      label: Text('Replace'),
                    ),
                  ],
                  selected: {_replace},
                  onSelectionChanged: (s) =>
                      setState(() => _replace = s.first),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedDay == null
              ? null
              : () {
                  final src = widget.sources
                      .firstWhere((s) => s.dayName == _selectedDay);
                  Navigator.pop(
                    context,
                    _CopyPickResult(
                      sourceDay: src.dayName,
                      sourceLabel: src.label,
                      replace: _replace,
                    ),
                  );
                },
          child: const Text('Copy'),
        ),
      ],
    );
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

/// A proportional day timeline (6 AM–10 PM). Each task is a block whose
/// height reflects its duration, so activities visibly "fill up" their slot.
/// Tapping an empty area adds a task at that time (snapped to 15 min).
class _DayTimeline extends StatelessWidget {
  final List<TaskModel> tasks;
  final bool isEditable;
  final void Function(TaskModel) onTapTask;
  final void Function(TaskModel) onDeleteTask;
  final void Function(int hour, int minute) onAddAt;

  const _DayTimeline({
    required this.tasks,
    required this.isEditable,
    required this.onTapTask,
    required this.onDeleteTask,
    required this.onAddAt,
  });

  static const int _startHour = 6; // 6 AM
  static const int _endHour = 22; // 10 PM
  static const double _hourHeight = 64;
  static const double _gutter = 52;
  static const double _topPad = 10;

  double _topFor(int minutes) =>
      _topPad + (minutes - _startHour * 60) / 60 * _hourHeight;

  void _addAtY(double dy) {
    final raw = _startHour * 60 + ((dy - _topPad) / _hourHeight * 60).round();
    final snapped = (raw / 15).round() * 15;
    final clamped = snapped.clamp(_startHour * 60, _endHour * 60 - 15);
    onAddAt(clamped ~/ 60, clamped % 60);
  }

  @override
  Widget build(BuildContext context) {
    final hours = _endHour - _startHour;
    final contentHeight = hours * _hourHeight + _topPad * 2;

    return SingleChildScrollView(
      child: SizedBox(
        height: contentHeight,
        child: Stack(
          children: [
            // Tap-empty-to-add layer (behind everything).
            if (isEditable)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapUp: (d) => _addAtY(d.localPosition.dy),
                ),
              ),

            // Hour gridlines + labels.
            for (int h = _startHour; h <= _endHour; h++) ...[
              Positioned(
                top: _topPad + (h - _startHour) * _hourHeight,
                left: _gutter,
                right: 0,
                child: Container(height: 1, color: AppColors.surfaceVariant),
              ),
              Positioned(
                top: _topPad + (h - _startHour) * _hourHeight - 7,
                left: 0,
                width: _gutter - 8,
                child: Text(
                  '${h.toString().padLeft(2, '0')}:00',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary, fontSize: 11),
                ),
              ),
            ],

            // Task blocks, sized by duration.
            for (final task in tasks)
              Positioned(
                top: _topFor(task.startMinutes.clamp(
                    _startHour * 60, _endHour * 60 - 15)),
                left: _gutter + 4,
                right: 8,
                height: (task.duration / 60 * _hourHeight).clamp(30, 1000),
                child: _TimelineBlock(
                  task: task,
                  isEditable: isEditable,
                  onTap: () => onTapTask(task),
                  onDelete: () => onDeleteTask(task),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineBlock extends StatelessWidget {
  final TaskModel task;
  final bool isEditable;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TimelineBlock({
    required this.task,
    required this.isEditable,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final start = task.startMinutes;
    final end = start + task.duration;
    String fmt(int m) =>
        '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
    final color = task.category.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: color.withAlpha(36),
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEditable ? onTap : null,
          child: Row(
            children: [
              Container(width: 4, color: color),
              const SizedBox(width: 8),
              Icon(task.category.icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${task.title}  ·  ${fmt(start)}–${fmt(end)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (isEditable)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  icon: const Icon(Icons.close,
                      color: AppColors.textSecondary),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
