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

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
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
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
    redirect: (context, state) {
      if (authState.isLoading) {
        return '/splash';
      }

      final isOnboarding = state.matchedLocation == '/onboarding';
      final isPinSetup = state.matchedLocation == '/pin-setup';
      final isBiometricsSetup = state.matchedLocation == '/biometrics-setup';
      final isLock = state.matchedLocation == '/lock';
      final isSplash = state.matchedLocation == '/splash';

      // 1. Onboarding Flow Check
      if (!authState.isOnboardingCompleted) {
        return isOnboarding ? null : '/onboarding';
      }

      // 2. PIN Setup Flow Check
      if (!authState.isPinSetup) {
        return (isPinSetup || isBiometricsSetup) ? null : '/pin-setup';
      }

      // 3. App Lock Screen Check (not authenticated for this session yet)
      if (!authState.isAuthenticated) {
        // Allow going to lock
        return isLock ? null : '/lock';
      }

      // 4. Authenticated, redirect away from onboarding/lock/pin-setup to dashboard
      if (isOnboarding || isPinSetup || isLock || isSplash) {
        return '/dashboard';
      }

      return null;
    },
  );
});
