import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { earn, spend }

class TransactionModel {
  final String id;
  final String memberId;
  final TransactionType type;
  final int amount;
  final String reason;
  final String? itemId;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.memberId,
    required this.type,
    required this.amount,
    required this.reason,
    this.itemId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'memberId': memberId,
        'type': type.name,
        'amount': amount,
        'reason': reason,
        'itemId': itemId,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) =>
      TransactionModel(
        id: id,
        memberId: map['memberId'] as String,
        type: TransactionType.values.byName(map['type'] as String),
        amount: map['amount'] as int,
        reason: map['reason'] as String,
        itemId: map['itemId'] as String?,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
      );
}
