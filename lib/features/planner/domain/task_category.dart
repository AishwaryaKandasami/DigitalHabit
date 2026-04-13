import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum TaskCategory {
  exercise('Exercise', Icons.directions_run, AppColors.exercise, true),
  study('Study', Icons.menu_book, AppColors.study, true),
  chores('Chores', Icons.cleaning_services, AppColors.chores, true),
  creative('Creative', Icons.palette, AppColors.creative, true),
  social('Social', Icons.people, AppColors.social, true),
  screenTime('Screen Time', Icons.phone_android, AppColors.screenTime, false),
  sleep('Sleep', Icons.bedtime, AppColors.sleep, true);

  final String displayName;
  final IconData icon;
  final Color color;
  final bool isHealthyByDefault;

  const TaskCategory(
      this.displayName, this.icon, this.color, this.isHealthyByDefault);
}

class TaskTemplates {
  TaskTemplates._();

  static const Map<TaskCategory, List<String>> templates = {
    TaskCategory.exercise: [
      'Morning Walk',
      'Cycling',
      'Swimming',
      'Yoga',
      'Sports Practice',
      'Outdoor Play',
    ],
    TaskCategory.study: [
      'Homework',
      'Reading',
      'Math Practice',
      'Science Project',
      'Language Practice',
      'Online Class',
    ],
    TaskCategory.chores: [
      'Clean Room',
      'Do Dishes',
      'Laundry',
      'Help Cook',
      'Water Plants',
      'Walk the Dog',
    ],
    TaskCategory.creative: [
      'Drawing',
      'Music Practice',
      'Writing',
      'Crafts',
      'Photography',
      'Dance',
    ],
    TaskCategory.social: [
      'Play with Friends',
      'Family Time',
      'Board Games',
      'Visit Grandparents',
      'Team Activity',
    ],
    TaskCategory.screenTime: [
      'Watch TV',
      'Play Video Games',
      'YouTube',
      'Social Media',
      'Minecraft',
      'Roblox',
    ],
    TaskCategory.sleep: [
      'Bedtime',
      'Nap',
      'Wind Down',
    ],
  };
}
