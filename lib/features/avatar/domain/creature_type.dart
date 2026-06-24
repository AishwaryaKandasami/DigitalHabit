import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum CreatureType {
  fireFox('Fire Fox', '🦊', AppColors.accentRed),
  waterDragon('Water Dragon', '🐉', AppColors.accentBlue),
  earthBunny('Earth Bunny', '🐰', AppColors.accentGreen),
  windOwl('Wind Owl', '🦉', AppColors.accent),
  starCat('Star Cat', '🐱', AppColors.primary),
  leafPanda('Leaf Panda', '🐼', AppColors.accentGreen),
  thunderWolf('Thunder Wolf', '🐺', AppColors.sleep),
  frostPenguin('Frost Penguin', '🐧', AppColors.study),
  skyRobin('Sky Robin', '🐦', AppColors.social),
  bumbleBee('Bumble Bee', '🐝', AppColors.accent),
  gardenButterfly('Garden Butterfly', '🦋', AppColors.creative);

  final String displayName;
  final String emoji;
  final Color color;

  const CreatureType(this.displayName, this.emoji, this.color);
}
