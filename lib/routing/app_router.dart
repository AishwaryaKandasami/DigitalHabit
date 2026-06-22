import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/welcome_screen.dart';
import '../features/auth/presentation/parent_signup_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/profile_picker_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/avatar/presentation/choose_avatar_screen.dart';
import '../features/avatar/presentation/avatar_screen.dart';
import '../features/dashboard/presentation/kid_dashboard_screen.dart';
import '../features/family/presentation/grownup_gate_screen.dart';
import '../features/family/presentation/family_management_screen.dart';
import '../features/planner/presentation/weekly_planner_screen.dart';
import '../features/planner/presentation/day_planner_screen.dart';
import '../features/tasks/presentation/task_completion_screen.dart';
import '../features/shop/presentation/shop_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Paths a signed-in family should be redirected away from (into the app).
const _publicOnlyPaths = {'/', '/signup', '/login'};

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final appUserAsync = ref.read(appUserProvider);

      if (authAsync.isLoading) return null;
      final firebaseUser = authAsync.value;
      final loc = state.matchedLocation;

      if (firebaseUser == null) {
        // Not signed in: only public paths allowed.
        return _publicOnlyPaths.contains(loc) ? null : '/';
      }

      // Signed in. Wait for the family lookup.
      if (appUserAsync.isLoading) return null;
      final appUser = appUserAsync.value;

      if (appUser == null || appUser.familyId == null) {
        // Signed in but no family mapping — allow public + onboarding.
        if (_publicOnlyPaths.contains(loc) || loc == '/choose-avatar') {
          return null;
        }
        return '/';
      }

      // Signed in with a family → into the app (single shell).
      if (_publicOnlyPaths.contains(loc)) return '/kid';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const ParentSignupScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
          path: '/choose-avatar',
          builder: (_, _) => const ChooseAvatarScreen()),
      GoRoute(
          path: '/who', builder: (_, _) => const ProfilePickerScreen()),

      // Grown-up area (PIN-gated monitor + setup).
      GoRoute(
        path: '/grownups',
        builder: (_, _) => const GrownupGateScreen(),
        routes: [
          GoRoute(
            path: 'family',
            builder: (_, _) => const FamilyManagementScreen(),
          ),
        ],
      ),

      // Single app shell = the kid experience for the active profile.
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
                NavigationDestination(icon: Icon(Icons.pets), label: 'Garden'),
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
                path: '/kid/shop', builder: (_, _) => const ShopScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/kid/avatar', builder: (_, _) => const AvatarScreen()),
          ]),
        ],
      ),
    ],
  );
});

/// Re-runs the redirect when auth state or the family mapping changes.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen(authStateProvider, (_, _) => notifyListeners());
    _ref.listen(appUserProvider, (_, _) => notifyListeners());
  }
  final Ref _ref;
}
