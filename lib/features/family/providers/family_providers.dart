import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/family_repository.dart';
import '../domain/family_model.dart';
import '../domain/member_model.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/providers/auth_providers.dart';

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository();
});

final familyProvider = StreamProvider<FamilyModel?>((ref) {
  final appUser = ref.watch(appUserProvider).value;
  if (appUser?.familyId == null) return Stream.value(null);
  return ref.read(familyRepositoryProvider).streamFamily(appUser!.familyId!);
});

final familyMembersProvider = StreamProvider<List<MemberModel>>((ref) {
  final appUser = ref.watch(appUserProvider).value;
  if (appUser?.familyId == null) return Stream.value([]);
  return ref.read(familyRepositoryProvider).streamMembers(appUser!.familyId!);
});

final childMembersProvider = Provider<List<MemberModel>>((ref) {
  final members = ref.watch(familyMembersProvider).value ?? [];
  return members.where((m) => m.role == UserRole.child).toList();
});

/// Which child profile is currently active (being played as). Null means
/// "not chosen yet" — [currentMemberProvider] then auto-selects the first
/// child, and the "Who's playing?" picker is shown when there are several.
class ActiveMemberIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? memberId) => state = memberId;
}

final activeMemberIdProvider =
    NotifierProvider<ActiveMemberIdNotifier, String?>(
        ActiveMemberIdNotifier.new);

/// The active child profile. Resolves the explicit selection if it still
/// exists, otherwise falls back to the first child so single-child families
/// "just work" with no picker.
final currentMemberProvider = Provider<MemberModel?>((ref) {
  final children = ref.watch(childMembersProvider);
  if (children.isEmpty) return null;
  final activeId = ref.watch(activeMemberIdProvider);
  if (activeId != null) {
    for (final m in children) {
      if (m.id == activeId) return m;
    }
  }
  return children.first;
});

/// Convenience: the active child's member id (for repository writes).
final activeMemberProvider = Provider<MemberModel?>((ref) {
  return ref.watch(currentMemberProvider);
});
