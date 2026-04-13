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
import '../features/planner/presentation/weekly_planner_screen.dart';
import '../features/planner/presentation/day_planner_screen.dart';
import '../features/planner/presentation/plan_review_screen.dart';

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
      GoRoute(path: '/', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const ParentSignupScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
          path: '/join-family',
          builder: (_, _) => const JoinFamilyScreen()),
      GoRoute(
          path: '/choose-avatar',
          builder: (_, _) => const ChooseAvatarScreen()),

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
                builder: (_, _) => const KidDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/kid/planner',
              builder: (_, _) => const WeeklyPlannerScreen(),
              routes: [
                GoRoute(
                  path: 'day/:dayName',
                  builder: (_, state) => DayPlannerScreen(
                    dayName: state.pathParameters['dayName']!,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/kid/shop',
                builder: (_, _) =>
                    const _PlaceholderScreen(title: 'Shop')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/kid/avatar',
                builder: (_, _) => const AvatarScreen()),
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
                builder: (_, _) => const ParentDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/parent/plans',
                builder: (_, _) => const PlanReviewScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/parent/family',
                builder: (_, _) => const FamilyManagementScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/parent/settings',
                builder: (_, _) =>
                    const _PlaceholderScreen(title: 'Settings')),
          ]),
        ],
      ),
    ],
  );
});
