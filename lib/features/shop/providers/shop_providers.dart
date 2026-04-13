import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/shop_repository.dart';
import '../domain/shop_item_model.dart';
import '../domain/inventory_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../../family/providers/family_providers.dart';

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository();
});

/// Stream all shop items for the current family.
final shopItemsProvider = StreamProvider<List<ShopItemModel>>((ref) {
  final appUser = ref.watch(appUserProvider).value;
  if (appUser?.familyId == null) return Stream.value([]);
  return ref.read(shopRepositoryProvider).streamShopItems(appUser!.familyId!);
});

/// Current member's inventory from the member document.
final inventoryProvider = Provider<InventoryModel>((ref) {
  final member = ref.watch(currentMemberProvider);
  if (member == null) return const InventoryModel();
  return member.inventory;
});

/// Selected shop category filter.
class ShopCategoryNotifier extends Notifier<ShopItemType?> {
  @override
  ShopItemType? build() => null;

  void set(ShopItemType? type) => state = type;
}

final shopCategoryProvider =
    NotifierProvider<ShopCategoryNotifier, ShopItemType?>(
        ShopCategoryNotifier.new);
