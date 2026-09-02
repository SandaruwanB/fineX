import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_provider.dart';
import '../../features/auth/presentation/biometrics_setup_page.dart';
import '../../features/auth/presentation/lock_page.dart';
import '../../features/auth/presentation/pin_setup_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../widgets/splash_page.dart';

import '../../features/accounts/presentation/accounts_page.dart';
import '../../features/categories/presentation/categories_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/analytics/presentation/analytics_page.dart';
import '../../features/tax/presentation/tax_page.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (previous, next) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);

    if (authState.isLoading) {
      return '/splash';
    }

    final isOnboarding = state.matchedLocation == '/onboarding';
    final isPinSetup = state.matchedLocation == '/pin-setup';
    final isBiometricsSetup = state.matchedLocation == '/biometrics-setup';
    final isLock = state.matchedLocation == '/lock';
    final isSplash = state.matchedLocation == '/splash';

    if (!authState.isOnboardingCompleted) {
      return isOnboarding ? null : '/onboarding';
    }

    if (!authState.isPinSetup) {
      return (isPinSetup || isBiometricsSetup) ? null : '/pin-setup';
    }

    if (!authState.isAuthenticated) {
      return isLock ? null : '/lock';
    }

    if (isOnboarding || isPinSetup || isLock || isSplash) {
      return '/dashboard';
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/pin-setup',
        builder: (context, state) => const PinSetupPage(),
      ),
      GoRoute(
        path: '/biometrics-setup',
        builder: (context, state) => const BiometricsSetupPage(),
      ),
      GoRoute(path: '/lock', builder: (context, state) => const LockPage()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/accounts',
        builder: (context, state) => const AccountsPage(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesPage(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsPage(),
      ),
      GoRoute(
        path: '/tax',
        builder: (context, state) => const TaxPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});
