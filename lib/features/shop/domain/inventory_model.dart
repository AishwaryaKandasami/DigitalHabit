/// Tracks owned items for a member. Stored in member doc as a map.
class InventoryModel {
  final List<OwnedItem> items;

  const InventoryModel({this.items = const []});

  bool ownsItem(String itemId) => items.any((i) => i.itemId == itemId);

  OwnedItem? getItem(String itemId) {
    try {
      return items.firstWhere((i) => i.itemId == itemId);
    } catch (_) {
      return null;
    }
  }

  InventoryModel addItem(String itemId, {int quantity = 1}) {
    final existing = getItem(itemId);
    if (existing != null) {
      return InventoryModel(
        items: items.map((i) {
          if (i.itemId == itemId) {
            return OwnedItem(itemId: i.itemId, quantity: i.quantity + quantity);
          }
          return i;
        }).toList(),
      );
    }
    return InventoryModel(
      items: [...items, OwnedItem(itemId: itemId, quantity: quantity)],
    );
  }

  InventoryModel removeItem(String itemId, {int quantity = 1}) {
    return InventoryModel(
      items: items
          .map((i) {
            if (i.itemId == itemId) {
              final newQty = i.quantity - quantity;
              if (newQty <= 0) return null;
              return OwnedItem(itemId: i.itemId, quantity: newQty);
            }
            return i;
          })
          .whereType<OwnedItem>()
          .toList(),
    );
  }

  List<Map<String, dynamic>> toList() =>
      items.map((i) => i.toMap()).toList();

  factory InventoryModel.fromList(List<dynamic>? list) {
    if (list == null || list.isEmpty) return const InventoryModel();
    return InventoryModel(
      items: list
          .map((e) => OwnedItem.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OwnedItem {
  final String itemId;
  final int quantity;

  const OwnedItem({required this.itemId, this.quantity = 1});

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'quantity': quantity,
      };

  factory OwnedItem.fromMap(Map<String, dynamic> map) => OwnedItem(
        itemId: map['itemId'] as String,
        quantity: map['quantity'] as int? ?? 1,
      );
}
