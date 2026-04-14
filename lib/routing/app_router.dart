import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/welcome_screen.dart';
import '../features/auth/presentation/parent_signup_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/join_family_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/avatar/presentation/choose_avatar_screen.dart';
import '../features/avatar/presentation/avatar_screen.dart';
import '../features/dashboard/presentation/kid_dashboard_screen.dart';
import '../features/dashboard/presentation/parent_dashboard_screen.dart';
import '../features/family/presentation/family_management_screen.dart';
import '../features/planner/presentation/weekly_planner_screen.dart';
import '../features/planner/presentation/day_planner_screen.dart';
import '../features/planner/presentation/plan_review_screen.dart';
import '../features/tasks/presentation/task_completion_screen.dart';
import '../features/tasks/presentation/task_verification_screen.dart';
import '../features/shop/presentation/shop_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Paths that a signed-in user should be redirected away from (they'd bounce
/// them straight to dashboard).
const _publicOnlyPaths = {'/', '/signup', '/login', '/join-family'};

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final appUserAsync = ref.read(appUserProvider);

      // Still loading auth state — don't redirect yet.
      if (authAsync.isLoading) return null;
      final firebaseUser = authAsync.value;
      if (firebaseUser == null) {
        // Not signed in: only allow public paths.
        final loc = state.matchedLocation;
        if (_publicOnlyPaths.contains(loc)) return null;
        // Any protected path → go home.
        return '/';
      }

      // Signed in. Wait for profile lookup before deciding.
      if (appUserAsync.isLoading) return null;
      final appUser = appUserAsync.value;
      final loc = state.matchedLocation;

      // Signed in but no profile (shouldn't happen after recovery path, but
      // handle gracefully): let them stay on public paths to re-setup.
      if (appUser == null) {
        if (_publicOnlyPaths.contains(loc) || loc == '/choose-avatar') {
          return null;
        }
        return '/';
      }

      // Signed in with a profile. Skip public-only screens → dashboard.
      final dashboard = appUser.isParent ? '/parent' : '/kid';
      if (_publicOnlyPaths.contains(loc)) return dashboard;
      return null;
    },
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
              builder: (_, _) => const KidDashboardScreen(),
              routes: [
                GoRoute(
                  path: 'tasks',
                  builder: (_, _) => const TaskCompletionScreen(),
                ),
              ],
            ),
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
                builder: (_, _) => const ShopScreen()),
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
                    icon: Icon(Icons.verified_user), label: 'Verify'),
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
                path: '/parent/verify',
                builder: (_, _) => const TaskVerificationScreen()),
          ]),
        ],
      ),
    ],
  );
});

/// Listenable that pokes GoRouter to re-run its redirect when auth state or
/// the user profile changes.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen(authStateProvider, (_, _) => notifyListeners());
    _ref.listen(appUserProvider, (_, _) => notifyListeners());
  }
  final Ref _ref;
}
