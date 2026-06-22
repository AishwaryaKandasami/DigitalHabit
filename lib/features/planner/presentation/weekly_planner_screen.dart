import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/widgets/loading_widget.dart';
import '../domain/plan_model.dart';
import '../domain/task_model.dart';
import '../providers/planner_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../family/providers/family_providers.dart';

class WeeklyPlannerScreen extends ConsumerStatefulWidget {
  const WeeklyPlannerScreen({super.key});

  @override
  ConsumerState<WeeklyPlannerScreen> createState() =>
      _WeeklyPlannerScreenState();
}

class _WeeklyPlannerScreenState extends ConsumerState<WeeklyPlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 7,
      vsync: this,
      initialIndex: _todayIndex(),
    );
  }

  int _todayIndex() {
    final weekday = DateTime.now().weekday; // 1=Mon, 7=Sun
    return weekday - 1;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Sync draft plan from Firestore existing plan (or create empty).
  void _syncDraftFromExisting(PlanModel? existingPlan) {
    final memberId = ref.read(currentMemberProvider)?.id;
    if (memberId == null) return;
    final weekStart = ref.read(selectedWeekStartProvider);

    if (existingPlan != null) {
      ref.read(draftPlanProvider.notifier).set(existingPlan);
    } else {
      final draft = PlanModel.empty(
        memberId: memberId,
        weekStart: weekStart,
      );
      ref.read(draftPlanProvider.notifier).set(draft);
    }
  }

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Copy the previous week's plan into the currently selected week.
  Future<void> _copyLastWeek() async {
    final appUser = ref.read(appUserProvider).value;
    final memberId = ref.read(currentMemberProvider)?.id;
    final draft = ref.read(draftPlanProvider);
    if (appUser?.familyId == null || memberId == null || draft == null) {
      return;
    }

    final currentMonday = DateTime.parse(ref.read(selectedWeekStartProvider));
    final prevMonday = currentMonday.subtract(const Duration(days: 7));
    final prevIso = _isoDate(prevMonday);

    final repo = ref.read(planRepositoryProvider);
    PlanModel? prevPlan;
    try {
      prevPlan = await repo.getPlanForWeek(
        appUser!.familyId!,
        memberId,
        prevIso,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      return;
    }

    if (prevPlan == null || prevPlan.totalTasks == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No plan with tasks found for the previous week '
              '(${DateFormat('MMM d').format(prevMonday)}).',
            ),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    final hasExisting = draft.totalTasks > 0;
    final replace = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Copy last week's plan?"),
        content: Text(
          hasExisting
              ? 'Last week has ${prevPlan!.totalTasks} tasks. This week already '
                  'has ${draft.totalTasks}. Replace this week with last week\'s '
                  'plan, or add them on top?'
              : 'Copy all ${prevPlan!.totalTasks} tasks from last week into this '
                  'week?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (hasExisting)
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Add on top'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(hasExisting ? 'Replace' : 'Copy'),
          ),
        ],
      ),
    );
    if (replace == null) return; // cancelled

    // Fresh task IDs so the copies are independent of last week's plan.
    final newDays = <String, List<TaskModel>>{};
    for (final day in PlanModel.dayNames) {
      final copies = prevPlan.tasksForDay(day).map((t) => TaskModel(
            taskId: IdGenerator.uuid(),
            hour: t.hour,
            minute: t.minute,
            duration: t.duration,
            title: t.title,
            category: t.category,
            customCategoryName: t.customCategoryName,
            isDigitalActivity: t.isDigitalActivity,
            isHealthy: t.isHealthy,
          ));
      if (replace) {
        newDays[day] = copies.toList();
      } else {
        newDays[day] = [...draft.tasksForDay(day), ...copies];
      }
    }

    ref.read(draftPlanProvider.notifier).set(draft.copyWith(days: newDays));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Copied ${prevPlan.totalTasks} tasks from last week. '
            'Review and tap Submit.',
          ),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    }
  }

  void _changeWeek(int deltaDays) {
    final current = ref.read(selectedWeekStartProvider);
    final parsed = DateTime.parse(current);
    final next = parsed.add(Duration(days: deltaDays));
    _setWeek(next);
  }

  Future<void> _pickWeekDate() async {
    final current = ref.read(selectedWeekStartProvider);
    final parsed = DateTime.parse(current);
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: parsed,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Pick any day in the week',
    );
    if (picked != null) {
      _setWeek(picked);
    }
  }

  void _setWeek(DateTime anyDayInWeek) {
    // Snap to Monday of that week.
    final monday =
        anyDayInWeek.subtract(Duration(days: anyDayInWeek.weekday - 1));
    final iso =
        '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
    // Clear draft so it re-syncs for the new week.
    ref.read(draftPlanProvider.notifier).set(null);
    ref.read(selectedWeekStartProvider.notifier).set(iso);
  }

  bool _needsSync(PlanModel? existing, PlanModel? draft, String? memberId) {
    if (draft == null) return true;
    // Draft belongs to a different child → reset and re-sync for the active one.
    if (memberId != null && draft.memberId != memberId) return true;
    // Different week → re-sync
    if (existing != null && existing.weekStart != draft.weekStart) return true;
    if (existing == null) {
      // No existing plan for this week: draft should be empty for the selected
      // week. Any mismatch in weekStart is handled above.
      return false;
    }
    // If existing Firestore state changed (status/parentNote/id), re-sync so
    // the kid sees parent's updates (e.g. revision notes).
    if (existing.id != draft.id) return true;
    if (existing.status != draft.status) return true;
    if ((existing.parentNote ?? '') != (draft.parentNote ?? '')) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(currentPlanProvider);
    final draft = ref.watch(draftPlanProvider);
    final weekStart = ref.watch(selectedWeekStartProvider);
    final memberId = ref.watch(currentMemberProvider)?.id;

    return planAsync.when(
      loading: () =>
          const Scaffold(body: LoadingWidget(message: 'Loading plan...')),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (existingPlan) {
        // Re-sync the draft whenever it diverges from Firestore — week change,
        // a switch to a different child, or an updated plan doc.
        if (_needsSync(existingPlan, draft, memberId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _syncDraftFromExisting(existingPlan);
          });
          return const Scaffold(body: LoadingWidget());
        }

        final plan = draft!;
        final isEditable = plan.isEditable;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Weekly Plan'),
            actions: [
              if (isEditable)
                IconButton(
                  onPressed: _copyLastWeek,
                  icon: const Icon(Icons.copy_all, color: Colors.white),
                  tooltip: "Copy last week's plan",
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: List.generate(7, (i) {
                final dayTasks = plan.tasksForDay(PlanModel.dayNames[i]);
                return Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(PlanModel.dayLabels[i]),
                      if (dayTasks.isNotEmpty)
                        Text('${dayTasks.length}',
                            style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                );
              }),
            ),
          ),
          body: Column(
            children: [
              // Week navigation header
              _WeekNavigator(
                weekStart: weekStart,
                onPrev: () => _changeWeek(-7),
                onNext: () => _changeWeek(7),
                onPick: _pickWeekDate,
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: List.generate(7, (i) {
                    final dayName = PlanModel.dayNames[i];
                    final tasks = plan.tasksForDay(dayName);
                    return _DayTaskList(
                      dayName: dayName,
                      tasks: tasks,
                      // Per-day: today & future stay editable after approval.
                      isEditable: plan.isDayEditable(dayName),
                      status: plan.status,
                      onOpenDay: () => context.push(
                        '/kid/planner/day/$dayName',
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),

          // Summary bar
          bottomNavigationBar: _PlanSummaryBar(plan: plan),
        );
      },
    );
  }
}

class _WeekNavigator extends StatelessWidget {
  final String weekStart; // ISO date
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPick;

  const _WeekNavigator({
    required this.weekStart,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final monday = DateTime.parse(weekStart);
    final sunday = monday.add(const Duration(days: 6));
    final fmt = DateFormat('MMM d');
    final label = '${fmt.format(monday)} - ${fmt.format(sunday)}, ${monday.year}';

    // Indicate if current week / past / future
    final today = DateTime.now();
    final todayMonday =
        today.subtract(Duration(days: today.weekday - 1));
    final isCurrent = monday.year == todayMonday.year &&
        monday.month == todayMonday.month &&
        monday.day == todayMonday.day;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: AppColors.primary.withAlpha(15),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous week',
          ),
          Expanded(
            child: InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: AppTextStyles.bodyBold.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (isCurrent)
                      Text('This week', style: AppTextStyles.caption)
                    else if (monday.isAfter(todayMonday))
                      Text('Upcoming week', style: AppTextStyles.caption)
                    else
                      Text('Past week', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next week',
          ),
        ],
      ),
    );
  }
}

class _DayTaskList extends StatelessWidget {
  final String dayName;
  final List tasks;
  final bool isEditable;
  final PlanStatus status;
  final VoidCallback onOpenDay;

  const _DayTaskList({
    required this.dayName,
    required this.tasks,
    required this.isEditable,
    required this.status,
    required this.onOpenDay,
  });

  bool get _isRevision => status == PlanStatus.revisionRequested;

  String get _emptyCtaLabel =>
      _isRevision ? 'Edit this day' : 'Add Tasks';

  String get _bottomCtaLabel =>
      _isRevision ? 'Edit this day' : 'Add More Tasks';

  IconData get _ctaIcon => _isRevision ? Icons.edit : Icons.add;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note,
                size: 64, color: AppColors.textSecondary.withAlpha(80)),
            const SizedBox(height: 12),
            Text('No tasks for this day', style: AppTextStyles.body),
            if (isEditable) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onOpenDay,
                icon: Icon(_ctaIcon),
                label: Text(_emptyCtaLabel),
              ),
            ],
          ],
        ),
      );
    }

    // Sort tasks by start time (hour + minute)
    final sorted = List.of(tasks)
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final task = sorted[index];
              final startMins = task.hour * 60 + task.minute;
              final endMins = startMins + task.duration;
              final endHour = (endMins ~/ 60) % 24;
              final endMin = endMins % 60;
              final timeStr =
                  '${task.hour.toString().padLeft(2, '0')}:${task.minute.toString().padLeft(2, '0')}';
              final endStr =
                  '${endHour.toString().padLeft(2, '0')}:${endMin.toString().padLeft(2, '0')}';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  // Tap the whole row to open the day editor (matches the
                  // bottom CTA). Only tappable when editing is allowed.
                  onTap: isEditable ? onOpenDay : null,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: task.category.color.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(task.category.icon,
                        color: task.category.color, size: 22),
                  ),
                  title: Text(task.title, style: AppTextStyles.bodyBold),
                  subtitle: Text(
                    '$timeStr - $endStr  (${task.duration}min)',
                    style: AppTextStyles.caption,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      task.isHealthy
                          ? const Icon(Icons.eco,
                              color: AppColors.accentGreen, size: 18)
                          : const Icon(Icons.phone_android,
                              color: AppColors.accentRed, size: 18),
                      if (isEditable) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right,
                            size: 20, color: AppColors.textSecondary),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (isEditable)
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenDay,
                icon: Icon(_ctaIcon),
                label: Text(_bottomCtaLabel),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlanSummaryBar extends StatelessWidget {
  final PlanModel plan;

  const _PlanSummaryBar({required this.plan});

  @override
  Widget build(BuildContext context) {
    final screenMins = plan.totalScreenTimeMinutes;
    final screenHours = (screenMins / 60).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryChip(
            icon: Icons.task_alt,
            label: '${plan.totalTasks} tasks',
            color: AppColors.primary,
          ),
          _SummaryChip(
            icon: Icons.eco,
            label: '${plan.totalHealthyTasks} healthy',
            color: AppColors.accentGreen,
          ),
          _SummaryChip(
            icon: Icons.phone_android,
            label: '${screenHours}h screen',
            color: screenMins > 840
                ? AppColors.accentRed
                : AppColors.textSecondary, // 14h/week = 2h/day avg
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption.copyWith(color: color)),
      ],
    );
  }
}
