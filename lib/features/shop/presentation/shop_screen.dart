import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/coin_badge.dart';
import '../../../core/widgets/loading_widget.dart';
import '../domain/shop_item_model.dart';
import '../providers/shop_providers.dart';
import '../../family/providers/family_providers.dart';
import '../../auth/providers/auth_providers.dart';
import 'inventory_screen.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(currentMemberProvider);
    final shopAsync = ref.watch(shopItemsProvider);
    final selectedCategory = ref.watch(shopCategoryProvider);
    final inventory = ref.watch(inventoryProvider);
    final coins = member?.wallet.coins ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          CoinBadge(coins: coins),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.backpack),
            tooltip: 'Inventory',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InventoryScreen()),
            ),
          ),
        ],
      ),
      body: shopAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.store,
                      size: 64, color: AppColors.textSecondary.withAlpha(80)),
                  const SizedBox(height: 12),
                  Text('Shop is empty', style: AppTextStyles.body),
                  const SizedBox(height: 4),
                  Text('Items will appear when your family is set up.',
                      style: AppTextStyles.caption),
                ],
              ),
            );
          }

          final filtered = selectedCategory == null
              ? items
              : items.where((i) => i.type == selectedCategory).toList();

          return Column(
            children: [
              // Category filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: selectedCategory == null,
                      onTap: () =>
                          ref.read(shopCategoryProvider.notifier).set(null),
                    ),
                    ...ShopItemType.values.map((type) => _FilterChip(
                          label: type.displayName,
                          icon: type.icon,
                          color: type.color,
                          selected: selectedCategory == type,
                          onTap: () =>
                              ref.read(shopCategoryProvider.notifier).set(type),
                        )),
                  ],
                ),
              ),

              // Items grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final owned = inventory.ownsItem(item.id);
                    final canAfford = coins >= item.cost;
                    return _ShopItemCard(
                      item: item,
                      owned: owned && !item.isConsumable,
                      canAfford: canAfford,
                      ownedQty: inventory.getItem(item.id)?.quantity ?? 0,
                      onBuy: () => _buyItem(context, ref, item),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _buyItem(
    BuildContext context,
    WidgetRef ref,
    ShopItemModel item,
  ) async {
    final member = ref.read(currentMemberProvider);
    if (member == null) return;

    if (member.wallet.coins < item.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Not enough coins! Need ${item.cost}, have ${member.wallet.coins}'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    // Non-consumable items can only be bought once
    if (!item.isConsumable && member.inventory.ownsItem(item.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already own this item!')),
      );
      return;
    }

    try {
      final appUser = ref.read(appUserProvider).value!;
      await ref.read(shopRepositoryProvider).purchaseItem(
            familyId: appUser.familyId!,
            memberId: appUser.memberId!,
            item: item,
          );

      if (context.mounted) {
        _showPurchaseSuccess(context, item);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showPurchaseSuccess(BuildContext context, ShopItemModel item) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 56))
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 12),
              Text('Purchased!', style: AppTextStyles.heading2),
              const SizedBox(height: 4),
              Text(item.name, style: AppTextStyles.body),
              const SizedBox(height: 4),
              Text('-${item.cost} coins',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.accentRed)),
              if (item.isConsumable) ...[
                const SizedBox(height: 8),
                Text('Use it from your inventory!',
                    style: AppTextStyles.caption),
              ],
            ],
          ),
        )
            .animate()
            .scale(
                begin: const Offset(0.8, 0.8),
                duration: 300.ms,
                curve: Curves.easeOut)
            .fadeIn(duration: 200.ms),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? Colors.white : color),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : null,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final ShopItemModel item;
  final bool owned;
  final bool canAfford;
  final int ownedQty;
  final VoidCallback onBuy;

  const _ShopItemCard({
    required this.item,
    required this.owned,
    required this.canAfford,
    required this.ownedQty,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: owned ? null : onBuy,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Emoji
              Expanded(
                child: Center(
                  child: Text(
                    item.emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
              // Name
              Text(item.name,
                  style: AppTextStyles.bodyBold,
                  textAlign: TextAlign.center),
              const SizedBox(height: 2),
              // Description
              Text(item.description,
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              // Price / owned badge
              if (owned)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Owned',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.accentGreen)),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.monetization_on,
                        size: 16,
                        color: canAfford
                            ? AppColors.accent
                            : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${item.cost}',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: canAfford
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (ownedQty > 0) ...[
                      const SizedBox(width: 6),
                      Text('(x$ownedQty)',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.accentGreen)),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
