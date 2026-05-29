import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/message_model.dart';

/// Firestore path for the messages subcollection of a family.
String _messagesPath(String familyId) => 'families/$familyId/messages';

class MessageRepository {
  final FirebaseFirestore _firestore;

  MessageRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Send a parent-authored message to a kid.
  Future<MessageModel> sendMessage({
    required String familyId,
    required String toMemberId,
    required String fromUid,
    required String fromName,
    required String text,
    MessageKind kind = MessageKind.reminder,
  }) async {
    final ref = _firestore.collection(_messagesPath(familyId)).doc();
    final msg = MessageModel(
      id: ref.id,
      toMemberId: toMemberId,
      fromUid: fromUid,
      fromName: fromName,
      text: text.trim(),
      kind: kind,
      sentAt: DateTime.now(),
    );
    await ref.set(msg.toMap());
    return msg;
  }

  /// Stream the most recent messages for a member (descending by sentAt).
  /// Caps at 30 to keep reads small on free tier.
  Stream<List<MessageModel>> streamForMember(
      String familyId, String memberId) {
    return _firestore
        .collection(_messagesPath(familyId))
        .where('toMemberId', isEqualTo: memberId)
        .orderBy('sentAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MessageModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// Mark every unread message for this kid as seen. Cheap when the list
  /// of unread ids is empty.
  Future<void> markAllSeen({
    required String familyId,
    required List<String> messageIds,
  }) async {
    if (messageIds.isEmpty) return;
    final batch = _firestore.batch();
    for (final id in messageIds) {
      batch.update(
        _firestore.collection(_messagesPath(familyId)).doc(id),
        {'seenByChild': true},
      );
    }
    await batch.commit();
  }
}
