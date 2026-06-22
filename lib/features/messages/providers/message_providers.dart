import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/message_repository.dart';
import '../domain/message_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../../family/providers/family_providers.dart';

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository();
});

/// Stream of recent messages addressed to the active child (kid view).
final myMessagesProvider = StreamProvider<List<MessageModel>>((ref) {
  final appUser = ref.watch(appUserProvider).value;
  final memberId = ref.watch(currentMemberProvider)?.id;
  if (appUser?.familyId == null || memberId == null) {
    return Stream.value(const <MessageModel>[]);
  }
  return ref
      .read(messageRepositoryProvider)
      .streamForMember(appUser!.familyId!, memberId);
});

/// Latest unread message for the kid, or null when there are none.
/// Drives the avatar speech bubble override.
final latestUnreadMessageProvider = Provider<MessageModel?>((ref) {
  final list = ref.watch(myMessagesProvider).value ?? const <MessageModel>[];
  for (final m in list) {
    if (!m.seenByChild) return m; // list is sorted newest-first
  }
  return null;
});

/// Count of unread messages for the kid.
final unreadMessagesCountProvider = Provider<int>((ref) {
  final list = ref.watch(myMessagesProvider).value ?? const <MessageModel>[];
  return list.where((m) => !m.seenByChild).length;
});

/// Stream of messages addressed to a specific kid (used by parent view if
/// needed later; unused for now but cheap to include).
final messagesForChildProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, memberId) {
  final appUser = ref.watch(appUserProvider).value;
  if (appUser?.familyId == null) {
    return Stream.value(const <MessageModel>[]);
  }
  return ref
      .read(messageRepositoryProvider)
      .streamForMember(appUser!.familyId!, memberId);
});
