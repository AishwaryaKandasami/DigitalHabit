import 'package:cloud_firestore/cloud_firestore.dart';

/// What kind of message — drives the icon + nudges the tone.
enum MessageKind {
  praise,      // "Great job!"
  nudge,       // "Don't forget your math!"
  reminder,    // generic
  autoNudge,   // app-generated reminder (not user-sent)
}

class MessageModel {
  final String id;
  final String toMemberId;
  /// Sender uid. Empty for auto-generated nudges.
  final String fromUid;
  /// Display name shown to the kid (e.g. "Mom").
  final String fromName;
  final String text;
  final MessageKind kind;
  final DateTime sentAt;
  final bool seenByChild;

  const MessageModel({
    required this.id,
    required this.toMemberId,
    required this.fromUid,
    required this.fromName,
    required this.text,
    required this.kind,
    required this.sentAt,
    this.seenByChild = false,
  });

  Map<String, dynamic> toMap() => {
        'toMemberId': toMemberId,
        'fromUid': fromUid,
        'fromName': fromName,
        'text': text,
        'kind': kind.name,
        'sentAt': Timestamp.fromDate(sentAt),
        'seenByChild': seenByChild,
      };

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) =>
      MessageModel(
        id: id,
        toMemberId: map['toMemberId'] as String,
        fromUid: map['fromUid'] as String? ?? '',
        fromName: map['fromName'] as String? ?? 'Parent',
        text: map['text'] as String? ?? '',
        kind: MessageKind.values
            .byName(map['kind'] as String? ?? 'reminder'),
        sentAt: (map['sentAt'] as Timestamp).toDate(),
        seenByChild: map['seenByChild'] as bool? ?? false,
      );
}
