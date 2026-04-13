import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class ParentShell extends StatelessWidget {
  final int currentIndex;
  final Widget child;
  final void Function(int) onTap;

  const ParentShell({
    super.key,
    required this.currentIndex,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.checklist), label: 'Plans'),
          BottomNavigationBarItem(
              icon: Icon(Icons.family_restroom), label: 'Family'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
