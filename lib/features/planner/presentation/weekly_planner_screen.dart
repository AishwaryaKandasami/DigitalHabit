import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/loading_widget.dart';
import '../domain/plan_model.dart';
import '../providers/planner_providers.dart';
import '../../auth/providers/auth_providers.dart';

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
    final appUser = ref.read(appUserProvider).value;
    if (appUser?.memberId == null) return;
    final weekStart = ref.read(selectedWeekStartProvider);

    if (existingPlan != null) {
      ref.read(draftPlanProvider.notifier).set(existingPlan);
    } else {
      final draft = PlanModel.empty(
        memberId: appUser!.memberId!,
        weekStart: weekStart,
      );
      ref.read(draftPlanProvider.notifier).set(draft);
    }
  }

  Future<void> _submitPlan() async {
    final appUser = ref.read(appUserProvider).value;
    final draft = ref.read(draftPlanProvider);
    if (appUser == null || draft == null) return;

    if (draft.totalTasks == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some tasks before submitting!')),
      );
      return;
    }

    try {
      final repo = ref.read(planRepositoryProvider);
      // Save the plan first
      final saved = await repo.savePlan(appUser.familyId!, draft);
      // Then submit for approval
      await repo.submitPlan(appUser.familyId!, saved.id);

      ref.invalidate(currentPlanProvider);
      ref.read(draftPlanProvider.notifier).set(null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan submitted for parent approval!'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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

  bool _needsSync(PlanModel? existing, PlanModel? draft) {
    if (draft == null) return true;
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

    return planAsync.when(
      loading: () =>
          const Scaffold(body: LoadingWidget(message: 'Loading plan...')),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (existingPlan) {
        // Re-sync draft whenever Firestore state diverges — ensures parent
        // revision notes & approvals reach the kid, and week changes reset
        // the draft.
        if (_needsSync(existingPlan, draft)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _syncDraftFromExisting(existingPlan);
          });
          return const Scaffold(body: LoadingWidget());
        }

        final plan = draft!;
        final isEditable = plan.isEditable;

        // Use Firestore plan as source of truth for status banner (falls back
        // to draft for brand-new/unsaved plans).
        final bannerPlan = existingPlan ?? plan;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Weekly Plan'),
            actions: [
              if (plan.isSubmittable)
                TextButton.icon(
                  onPressed: _submitPlan,
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text('Submit',
                      style: TextStyle(color: Colors.white)),
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

              // Status banner (from Firestore source of truth)
              _StatusBanner(
                status: bannerPlan.status,
                parentNote: bannerPlan.parentNote,
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
                      isEditable: isEditable,
                      onAddTask: () => context.push(
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

class _StatusBanner extends StatelessWidget {
  final PlanStatus status;
  final String? parentNote;

  const _StatusBanner({required this.status, this.parentNote});

  @override
  Widget build(BuildContext context) {
    if (status == PlanStatus.draft) return const SizedBox.shrink();

    final (color, icon, label) = switch (status) {
      PlanStatus.pendingApproval => (
          AppColors.accent,
          Icons.hourglass_top,
          'Waiting for parent approval'
        ),
      PlanStatus.approved => (
          AppColors.accentGreen,
          Icons.check_circle,
          'Approved by parent!'
        ),
      PlanStatus.revisionRequested => (
          AppColors.accentRed,
          Icons.edit_note,
          'Parent requested changes'
        ),
      _ => (AppColors.textSecondary, Icons.info, ''),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: color.withAlpha(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label, style: AppTextStyles.bodyBold.copyWith(color: color)),
            ],
          ),
          if (parentNote != null && parentNote!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '"$parentNote"',
              style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayTaskList extends StatelessWidget {
  final String dayName;
  final List tasks;
  final bool isEditable;
  final VoidCallback onAddTask;

  const _DayTaskList({
    required this.dayName,
    required this.tasks,
    required this.isEditable,
    required this.onAddTask,
  });

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
                onPressed: onAddTask,
                icon: const Icon(Icons.add),
                label: const Text('Add Tasks'),
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
                  trailing: task.isHealthy
                      ? const Icon(Icons.eco,
                          color: AppColors.accentGreen, size: 18)
                      : const Icon(Icons.phone_android,
                          color: AppColors.accentRed, size: 18),
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
                onPressed: onAddTask,
                icon: const Icon(Icons.add),
                label: const Text('Add More Tasks'),
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
