import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/task_log_repository.dart';
import '../domain/task_log_model.dart';
import '../../auth/providers/auth_providers.dart';

final taskLogRepositoryProvider = Provider<TaskLogRepository>((ref) {
  return TaskLogRepository();
});

/// Today's date as ISO string.
String todayDate() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

/// Stream today's completed task logs for the current child.
final todayLogsProvider = StreamProvider<List<TaskLogModel>>((ref) {
  final appUser = ref.watch(appUserProvider).value;
  if (appUser?.familyId == null || appUser?.memberId == null) {
    return Stream.value([]);
  }
  return ref.read(taskLogRepositoryProvider).streamLogsForDate(
        appUser!.familyId!,
        appUser.memberId!,
        todayDate(),
      );
});

/// Stream all pending verification logs for the family (parent view).
final pendingVerificationProvider = StreamProvider<List<TaskLogModel>>((ref) {
  final appUser = ref.watch(appUserProvider).value;
  if (appUser?.familyId == null) return Stream.value([]);
  return ref
      .read(taskLogRepositoryProvider)
      .streamPendingVerification(appUser!.familyId!);
});
