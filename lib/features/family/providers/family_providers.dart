import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/family_repository.dart';
import '../domain/family_model.dart';
import '../domain/member_model.dart';
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

final currentMemberProvider = Provider<MemberModel?>((ref) {
  final appUser = ref.watch(appUserProvider).value;
  final members = ref.watch(familyMembersProvider).value ?? [];
  if (appUser?.memberId == null) return null;
  try {
    return members.firstWhere((m) => m.id == appUser!.memberId);
  } catch (_) {
    return null;
  }
});

final childMembersProvider = Provider<List<MemberModel>>((ref) {
  final members = ref.watch(familyMembersProvider).value ?? [];
  return members.where((m) => m.role.name == 'child').toList();
});
