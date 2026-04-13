import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/welcome_screen.dart';
import '../features/auth/presentation/parent_signup_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/join_family_screen.dart';
import '../features/avatar/presentation/choose_avatar_screen.dart';
import '../features/avatar/presentation/avatar_screen.dart';
import '../features/dashboard/presentation/kid_dashboard_screen.dart';
import '../features/dashboard/presentation/parent_dashboard_screen.dart';
import '../features/family/presentation/family_management_screen.dart';

// Placeholder screens for tabs not yet built
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title - Coming Soon!',
            style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      // Auth routes
      GoRoute(path: '/', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const ParentSignupScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/join-family',
          builder: (_, __) => const JoinFamilyScreen()),
      GoRoute(
          path: '/choose-avatar',
          builder: (_, __) => const ChooseAvatarScreen()),

      // Kid shell with bottom nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (i) => navigationShell.goBranch(i),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(
                    icon: Icon(Icons.calendar_month), label: 'Planner'),
                NavigationDestination(
                    icon: Icon(Icons.shopping_bag), label: 'Shop'),
                NavigationDestination(icon: Icon(Icons.pets), label: 'Avatar'),
              ],
            ),
          );
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/kid',
                builder: (_, __) => const KidDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/kid/planner',
                builder: (_, __) =>
                    const _PlaceholderScreen(title: 'Planner')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/kid/shop',
                builder: (_, __) =>
                    const _PlaceholderScreen(title: 'Shop')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/kid/avatar',
                builder: (_, __) => const AvatarScreen()),
          ]),
        ],
      ),

      // Parent shell with bottom nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (i) => navigationShell.goBranch(i),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(
                    icon: Icon(Icons.checklist), label: 'Plans'),
                NavigationDestination(
                    icon: Icon(Icons.family_restroom), label: 'Family'),
                NavigationDestination(
                    icon: Icon(Icons.settings), label: 'Settings'),
              ],
            ),
          );
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/parent',
                builder: (_, __) => const ParentDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/parent/plans',
                builder: (_, __) =>
                    const _PlaceholderScreen(title: 'Plan Reviews')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/parent/family',
                builder: (_, __) => const FamilyManagementScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/parent/settings',
                builder: (_, __) =>
                    const _PlaceholderScreen(title: 'Settings')),
          ]),
        ],
      ),
    ],
  );
});
