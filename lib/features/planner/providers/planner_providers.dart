import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/plan_repository.dart';
import '../domain/plan_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../../family/providers/family_providers.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepository();
});

/// Current week start date (Monday) as ISO string.
String currentWeekStart() {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
}

/// Selected week start — defaults to current week.
class SelectedWeekStartNotifier extends Notifier<String> {
  @override
  String build() => currentWeekStart();

  void set(String weekStart) => state = weekStart;
}

final selectedWeekStartProvider =
    NotifierProvider<SelectedWeekStartNotifier, String>(
        SelectedWeekStartNotifier.new);

/// Stream the active child's plan for the selected week.
final currentPlanProvider = StreamProvider<PlanModel?>((ref) {
  final appUser = ref.watch(appUserProvider).value;
  final memberId = ref.watch(currentMemberProvider)?.id;
  final weekStart = ref.watch(selectedWeekStartProvider);
  if (appUser?.familyId == null || memberId == null) {
    return Stream.value(null);
  }
  return ref.read(planRepositoryProvider).streamPlanForWeek(
        appUser!.familyId!,
        memberId,
        weekStart,
      );
});

/// Stream all plans for the family (grown-up history view).
final allPlansProvider = StreamProvider<List<PlanModel>>((ref) {
  final appUser = ref.watch(appUserProvider).value;
  if (appUser?.familyId == null) return Stream.value([]);
  return ref.read(planRepositoryProvider).streamAllPlans(appUser!.familyId!);
});

/// Local draft plan for editing (before saving to Firestore).
class DraftPlanNotifier extends Notifier<PlanModel?> {
  @override
  PlanModel? build() {
    // Discard the draft whenever the active child changes, so one kid's
    // in-progress edits can never leak into another kid's plan.
    ref.listen(activeMemberIdProvider, (prev, next) {
      if (prev != next) state = null;
    });
    return null;
  }

  void set(PlanModel? plan) => state = plan;

  void updateDays(Map<String, List<dynamic>> days) {
    if (state == null) return;
    state = state!.copyWith(days: days.cast());
  }
}

final draftPlanProvider =
    NotifierProvider<DraftPlanNotifier, PlanModel?>(DraftPlanNotifier.new);
