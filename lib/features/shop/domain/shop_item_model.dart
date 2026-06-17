import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum ShopItemType {
  food('Food', Icons.restaurant, AppColors.accent),
  potion('Potion', Icons.science, AppColors.accentGreen),
  accessory('Accessory', Icons.auto_awesome, AppColors.primary),
  background('Background', Icons.landscape, AppColors.accentBlue);

  final String displayName;
  final IconData icon;
  final Color color;

  const ShopItemType(this.displayName, this.icon, this.color);
}

class ShopItemModel {
  final String id;
  final String name;
  final String description;
  final ShopItemType type;
  final int cost;
  final String emoji;
  final int moodBoost;
  final int healthBoost;

  const ShopItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.cost,
    required this.emoji,
    this.moodBoost = 0,
    this.healthBoost = 0,
  });

  bool get isConsumable => type == ShopItemType.food || type == ShopItemType.potion;

  /// Resolve an equipped/owned itemId to its catalog entry (emoji + type).
  /// The shop is always seeded from [defaultItems], so this static lookup is
  /// enough — no Firestore read needed to render cosmetics.
  static ShopItemModel? byId(String id) {
    for (final i in defaultItems) {
      if (i.id == id) return i;
    }
    return null;
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'type': type.name,
        'cost': cost,
        'emoji': emoji,
        'moodBoost': moodBoost,
        'healthBoost': healthBoost,
      };

  factory ShopItemModel.fromMap(String id, Map<String, dynamic> map) =>
      ShopItemModel(
        id: id,
        name: map['name'] as String,
        description: map['description'] as String? ?? '',
        type: ShopItemType.values.byName(map['type'] as String),
        cost: map['cost'] as int,
        emoji: map['emoji'] as String? ?? '',
        moodBoost: map['moodBoost'] as int? ?? 0,
        healthBoost: map['healthBoost'] as int? ?? 0,
      );

  /// Default shop items seeded when a family is created.
  static const List<ShopItemModel> defaultItems = [
    // Food (mood restore)
    ShopItemModel(
      id: 'food_apple',
      name: 'Apple',
      description: 'A healthy snack. +10 mood',
      type: ShopItemType.food,
      cost: 10,
      emoji: '🍎',
      moodBoost: 10,
    ),
    ShopItemModel(
      id: 'food_pizza',
      name: 'Pizza Slice',
      description: 'Comfort food! +15 mood',
      type: ShopItemType.food,
      cost: 20,
      emoji: '🍕',
      moodBoost: 15,
    ),
    ShopItemModel(
      id: 'food_cake',
      name: 'Birthday Cake',
      description: 'A special treat! +25 mood',
      type: ShopItemType.food,
      cost: 30,
      emoji: '🎂',
      moodBoost: 25,
    ),

    // Potions (health restore)
    ShopItemModel(
      id: 'potion_small',
      name: 'Small Potion',
      description: 'Restores +15 health',
      type: ShopItemType.potion,
      cost: 25,
      emoji: '🧪',
      healthBoost: 15,
    ),
    ShopItemModel(
      id: 'potion_large',
      name: 'Healing Potion',
      description: 'Restores +25 health',
      type: ShopItemType.potion,
      cost: 40,
      emoji: '💊',
      healthBoost: 25,
    ),
    ShopItemModel(
      id: 'potion_mega',
      name: 'Mega Elixir',
      description: '+20 mood and +20 health',
      type: ShopItemType.potion,
      cost: 60,
      emoji: '✨',
      moodBoost: 20,
      healthBoost: 20,
    ),

    // Accessories (cosmetic)
    ShopItemModel(
      id: 'acc_hat',
      name: 'Party Hat',
      description: 'A festive party hat!',
      type: ShopItemType.accessory,
      cost: 50,
      emoji: '🎩',
    ),
    ShopItemModel(
      id: 'acc_bow',
      name: 'Bow Tie',
      description: 'Looking fancy!',
      type: ShopItemType.accessory,
      cost: 75,
      emoji: '🎀',
    ),
    ShopItemModel(
      id: 'acc_crown',
      name: 'Golden Crown',
      description: 'Fit for royalty!',
      type: ShopItemType.accessory,
      cost: 150,
      emoji: '👑',
    ),
    ShopItemModel(
      id: 'acc_glasses',
      name: 'Cool Shades',
      description: 'Too cool for school.',
      type: ShopItemType.accessory,
      cost: 100,
      emoji: '😎',
    ),
    ShopItemModel(
      id: 'acc_wings',
      name: 'Angel Wings',
      description: 'Spread your wings!',
      type: ShopItemType.accessory,
      cost: 200,
      emoji: '🪽',
    ),

    // Backgrounds
    ShopItemModel(
      id: 'bg_forest',
      name: 'Enchanted Forest',
      description: 'A magical forest scene.',
      type: ShopItemType.background,
      cost: 100,
      emoji: '🌲',
    ),
    ShopItemModel(
      id: 'bg_ocean',
      name: 'Ocean Waves',
      description: 'Calming ocean view.',
      type: ShopItemType.background,
      cost: 150,
      emoji: '🌊',
    ),
    ShopItemModel(
      id: 'bg_space',
      name: 'Outer Space',
      description: 'Among the stars!',
      type: ShopItemType.background,
      cost: 200,
      emoji: '🚀',
    ),
    ShopItemModel(
      id: 'bg_castle',
      name: 'Royal Castle',
      description: 'A grand castle backdrop.',
      type: ShopItemType.background,
      cost: 300,
      emoji: '🏰',
    ),
  ];
}
