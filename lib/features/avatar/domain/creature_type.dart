import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum CreatureType {
  fireFox('Fire Fox', '🦊', AppColors.accentRed),
  waterDragon('Water Dragon', '🐉', AppColors.accentBlue),
  earthBunny('Earth Bunny', '🐰', AppColors.accentGreen),
  windOwl('Wind Owl', '🦉', AppColors.accent),
  starCat('Star Cat', '🐱', AppColors.primary);

  final String displayName;
  final String emoji;
  final Color color;

  const CreatureType(this.displayName, this.emoji, this.color);
}
