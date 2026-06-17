import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../domain/shop_item_model.dart';
import '../providers/shop_providers.dart';
import '../../family/providers/family_providers.dart';
import '../../auth/providers/auth_providers.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(currentMemberProvider);
    final shopItemsAsync = ref.watch(shopItemsProvider);
    final inventory = ref.watch(inventoryProvider);

    if (member == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final ownedItems = inventory.items;

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: shopItemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allItems) {
          // Map item IDs to shop items for display
          final itemMap = {for (final i in allItems) i.id: i};
          final displayItems = ownedItems
              .where((owned) => itemMap.containsKey(owned.itemId))
              .toList();

          if (displayItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.backpack,
                      size: 64, color: AppColors.textSecondary.withAlpha(80)),
                  const SizedBox(height: 12),
                  Text('Inventory is empty', style: AppTextStyles.heading3),
                  const SizedBox(height: 4),
                  Text('Buy items from the shop!',
                      style: AppTextStyles.caption),
                ],
              ),
            );
          }

          // Group by type
          final grouped = <ShopItemType, List<_InventoryEntry>>{};
          for (final owned in displayItems) {
            final item = itemMap[owned.itemId]!;
            grouped
                .putIfAbsent(item.type, () => [])
                .add(_InventoryEntry(item: item, quantity: owned.quantity));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(entry.key.icon,
                            color: entry.key.color, size: 20),
                        const SizedBox(width: 8),
                        Text(entry.key.displayName,
                            style: AppTextStyles.heading3),
                      ],
                    ),
                  ),
                  ...entry.value.map((inv) => _InventoryTile(
                        entry: inv,
                        avatar: member.avatarState,
                        onUse: inv.item.isConsumable
                            ? () => _useItem(context, ref, inv.item)
                            : null,
                        onEquip: (inv.item.type == ShopItemType.accessory ||
                                inv.item.type == ShopItemType.background)
                            ? () =>
                                _toggleAccessory(context, ref, inv.item.id)
                            : null,
                        isEquipped: member.avatarState.accessories
                            .contains(inv.item.id),
                      )),
                  const SizedBox(height: 8),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _useItem(
    BuildContext context,
    WidgetRef ref,
    ShopItemModel item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Use ${item.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            if (item.moodBoost > 0)
              Text('+${item.moodBoost} mood',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.moodHappy)),
            if (item.healthBoost > 0)
              Text('+${item.healthBoost} health',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.accentGreen)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Use'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final appUser = ref.read(appUserProvider).value!;
      await ref.read(shopRepositoryProvider).useItem(
            familyId: appUser.familyId!,
            memberId: appUser.memberId!,
            item: item,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Used ${item.name}!'
                '${item.moodBoost > 0 ? " +${item.moodBoost} mood" : ""}'
                '${item.healthBoost > 0 ? " +${item.healthBoost} health" : ""}'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _toggleAccessory(
    BuildContext context,
    WidgetRef ref,
    String itemId,
  ) async {
    try {
      final appUser = ref.read(appUserProvider).value!;
      await ref.read(shopRepositoryProvider).toggleAccessory(
            familyId: appUser.familyId!,
            memberId: appUser.memberId!,
            itemId: itemId,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _InventoryEntry {
  final ShopItemModel item;
  final int quantity;

  const _InventoryEntry({required this.item, required this.quantity});
}

class _InventoryTile extends StatelessWidget {
  final _InventoryEntry entry;
  final dynamic avatar;
  final VoidCallback? onUse;
  final VoidCallback? onEquip;
  final bool isEquipped;

  const _InventoryTile({
    required this.entry,
    required this.avatar,
    this.onUse,
    this.onEquip,
    this.isEquipped = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isEquipped ? AppColors.primary.withAlpha(15) : null,
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: entry.item.type.color.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(entry.item.emoji,
                style: const TextStyle(fontSize: 24)),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(entry.item.name, style: AppTextStyles.bodyBold),
            ),
            if (entry.item.isConsumable)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('x${entry.quantity}',
                    style: AppTextStyles.caption),
              ),
          ],
        ),
        subtitle: Text(entry.item.description, style: AppTextStyles.caption),
        trailing: onUse != null
            ? FilledButton(
                onPressed: onUse,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text('Use', style: TextStyle(fontSize: 12)),
              )
            : onEquip != null
                ? FilledButton(
                    onPressed: onEquip,
                    style: FilledButton.styleFrom(
                      backgroundColor: isEquipped
                          ? AppColors.textSecondary
                          : AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      isEquipped ? 'Remove' : 'Equip',
                      style: const TextStyle(fontSize: 12),
                    ),
                  )
                : null,
      ),
    );
  }
}
