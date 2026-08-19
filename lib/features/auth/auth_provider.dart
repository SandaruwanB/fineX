import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/preference_service.dart';
import '../../core/services/secure_storage_service.dart';

class AuthState {
  final bool isOnboardingCompleted;
  final bool isPinSetup;
  final bool isBiometricsEnabled;
  final bool isAuthenticated;
  final bool isLoading;

  AuthState({
    required this.isOnboardingCompleted,
    required this.isPinSetup,
    required this.isBiometricsEnabled,
    required this.isAuthenticated,
    required this.isLoading,
  });

  AuthState.initial()
    : isOnboardingCompleted = false,
      isPinSetup = false,
      isBiometricsEnabled = false,
      isAuthenticated = false,
      isLoading = true;

  AuthState copyWith({
    bool? isOnboardingCompleted,
    bool? isPinSetup,
    bool? isBiometricsEnabled,
    bool? isAuthenticated,
    bool? isLoading,
  }) {
    return AuthState(
      isOnboardingCompleted:
          isOnboardingCompleted ?? this.isOnboardingCompleted,
      isPinSetup: isPinSetup ?? this.isPinSetup,
      isBiometricsEnabled: isBiometricsEnabled ?? this.isBiometricsEnabled,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final PreferenceService _preferenceService;
  final SecureStorageService _secureStorageService;

  AuthNotifier(this._preferenceService, this._secureStorageService)
    : super(AuthState.initial()) {
    init();
  }

  Future<void> init() async {
    final onboardingCompleted = _preferenceService.isOnboardingCompleted;
    final pinSetup = await _secureStorageService.hasPin();
    final biometricsEnabled = _preferenceService.isBiometricsEnabled;

    state = AuthState(
      isOnboardingCompleted: onboardingCompleted,
      isPinSetup: pinSetup,
      isBiometricsEnabled: biometricsEnabled,
      isAuthenticated: false,
      isLoading: false,
    );
  }

  Future<void> completeOnboarding() async {
    await _preferenceService.setOnboardingCompleted(true);
    state = state.copyWith(isOnboardingCompleted: true);
  }

  Future<void> savePin(String pin) async {
    await _secureStorageService.savePin(pin);
    state = state.copyWith(isPinSetup: true);
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _preferenceService.setBiometricsEnabled(enabled);
    state = state.copyWith(isBiometricsEnabled: enabled);
  }

  void authenticateSession(bool authenticated) {
    state = state.copyWith(isAuthenticated: authenticated);
  }

  Future<bool> verifyPin(String enteredPin) async {
    final savedPin = await _secureStorageService.getPin();
    if (savedPin == enteredPin) {
      authenticateSession(true);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    // Session logout, doesn't clear stored PIN/preferences
    state = state.copyWith(isAuthenticated: false);
  }

  Future<void> resetAll() async {
    await _preferenceService.clear();
    await _secureStorageService.deletePin();
    state = AuthState(
      isOnboardingCompleted: false,
      isPinSetup: false,
      isBiometricsEnabled: false,
      isAuthenticated: false,
      isLoading: false,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final preferenceService = ref.watch(preferenceServiceProvider);
  final secureStorageService = ref.watch(secureStorageServiceProvider);
  return AuthNotifier(preferenceService, secureStorageService);
});
