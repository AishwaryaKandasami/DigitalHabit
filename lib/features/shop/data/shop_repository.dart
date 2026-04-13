import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../domain/shop_item_model.dart';
import '../domain/inventory_model.dart';
import '../domain/transaction_model.dart';
import '../../family/domain/member_model.dart';
import '../../avatar/domain/avatar_state.dart';
import '../../avatar/domain/evolution_calculator.dart';

class ShopRepository {
  final FirebaseFirestore _firestore;

  ShopRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Seed default shop items for a new family.
  Future<void> seedShopItems(String familyId) async {
    final batch = _firestore.batch();
    for (final item in ShopItemModel.defaultItems) {
      final ref = _firestore
          .collection(FirestorePaths.shopItems(familyId))
          .doc(item.id);
      batch.set(ref, item.toMap());
    }
    await batch.commit();
  }

  /// Stream all shop items for a family.
  Stream<List<ShopItemModel>> streamShopItems(String familyId) {
    return _firestore
        .collection(FirestorePaths.shopItems(familyId))
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ShopItemModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// Purchase an item: deduct coins, add to inventory, create transaction.
  Future<void> purchaseItem({
    required String familyId,
    required String memberId,
    required ShopItemModel item,
  }) async {
    final memberRef = _firestore
        .collection(FirestorePaths.members(familyId))
        .doc(memberId);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(memberRef);
      final member = MemberModel.fromMap(snap.id, snap.data()!);

      if (member.wallet.coins < item.cost) {
        throw Exception('Not enough coins! Need ${item.cost}, have ${member.wallet.coins}');
      }

      // Parse inventory from member doc
      final inventoryList = snap.data()!['inventory'] as List<dynamic>?;
      final inventory = InventoryModel.fromList(inventoryList);
      final updatedInventory = inventory.addItem(item.id);

      txn.update(memberRef, {
        'wallet.coins': FieldValue.increment(-item.cost),
        'inventory': updatedInventory.toList(),
      });

      // Transaction record
      final txRef = _firestore
          .collection(FirestorePaths.transactions(familyId))
          .doc();
      txn.set(txRef, TransactionModel(
        id: txRef.id,
        memberId: memberId,
        type: TransactionType.spend,
        amount: item.cost,
        reason: 'Purchased: ${item.name}',
        itemId: item.id,
        createdAt: DateTime.now(),
      ).toMap());
    });
  }

  /// Use a consumable item: remove from inventory, apply effects to avatar.
  Future<void> useItem({
    required String familyId,
    required String memberId,
    required ShopItemModel item,
  }) async {
    if (!item.isConsumable) {
      throw Exception('${item.name} is not consumable');
    }

    final memberRef = _firestore
        .collection(FirestorePaths.members(familyId))
        .doc(memberId);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(memberRef);
      final member = MemberModel.fromMap(snap.id, snap.data()!);

      final inventoryList = snap.data()!['inventory'] as List<dynamic>?;
      final inventory = InventoryModel.fromList(inventoryList);

      if (!inventory.ownsItem(item.id)) {
        throw Exception("You don't own ${item.name}");
      }

      final updatedInventory = inventory.removeItem(item.id);

      // Apply effects to avatar
      AvatarState updatedAvatar = member.avatarState;
      if (item.moodBoost > 0) {
        updatedAvatar =
            EvolutionCalculator.applyMoodChange(updatedAvatar, item.moodBoost);
      }
      if (item.healthBoost > 0) {
        updatedAvatar =
            EvolutionCalculator.applyHealthChange(updatedAvatar, item.healthBoost);
      }

      txn.update(memberRef, {
        'inventory': updatedInventory.toList(),
        'avatarState': updatedAvatar.toMap(),
      });
    });
  }

  /// Equip/unequip an accessory on the avatar.
  Future<void> toggleAccessory({
    required String familyId,
    required String memberId,
    required String itemId,
  }) async {
    final memberRef = _firestore
        .collection(FirestorePaths.members(familyId))
        .doc(memberId);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(memberRef);
      final member = MemberModel.fromMap(snap.id, snap.data()!);

      final accessories = List<String>.from(member.avatarState.accessories);
      if (accessories.contains(itemId)) {
        accessories.remove(itemId);
      } else {
        accessories.add(itemId);
      }

      final updatedAvatar =
          member.avatarState.copyWith(accessories: accessories);

      txn.update(memberRef, {
        'avatarState': updatedAvatar.toMap(),
      });
    });
  }
}
