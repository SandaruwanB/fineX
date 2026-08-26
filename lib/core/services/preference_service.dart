import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  final SharedPreferences _prefs;

  PreferenceService(this._prefs);

  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyBiometricsEnabled = 'biometrics_enabled';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyPrivacyMode = 'privacy_mode';
  static const String _keyBaseCurrency = 'base_currency';

  bool get isOnboardingCompleted =>
      _prefs.getBool(_keyOnboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_keyOnboardingCompleted, completed);
  }

  bool get isBiometricsEnabled =>
      _prefs.getBool(_keyBiometricsEnabled) ?? false;

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _prefs.setBool(_keyBiometricsEnabled, enabled);
  }

  bool get isDarkMode =>
      _prefs.getBool(_keyThemeMode) ?? true; // Default to dark mode for premium look

  Future<void> setDarkMode(bool isDark) async {
    await _prefs.setBool(_keyThemeMode, isDark);
  }

  bool get isPrivacyModeEnabled =>
      _prefs.getBool(_keyPrivacyMode) ?? false;

  Future<void> setPrivacyModeEnabled(bool enabled) async {
    await _prefs.setBool(_keyPrivacyMode, enabled);
  }

  String get baseCurrency =>
      _prefs.getString(_keyBaseCurrency) ?? 'USD';

  Future<void> setBaseCurrency(String currency) async {
    await _prefs.setString(_keyBaseCurrency, currency);
  }

  Future<void> clear() async {
    await _prefs.clear();
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPreferencesProvider in main.dart');
});

final preferenceServiceProvider = Provider<PreferenceService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PreferenceService(prefs);
});

class PrivacyModeNotifier extends StateNotifier<bool> {
  final PreferenceService _prefService;

  PrivacyModeNotifier(this._prefService) : super(_prefService.isPrivacyModeEnabled);

  Future<void> togglePrivacyMode() async {
    final newState = !state;
    await _prefService.setPrivacyModeEnabled(newState);
    state = newState;
  }
}

final privacyModeProvider = StateNotifierProvider<PrivacyModeNotifier, bool>((ref) {
  final prefService = ref.watch(preferenceServiceProvider);
  return PrivacyModeNotifier(prefService);
});

class BaseCurrencyNotifier extends StateNotifier<String> {
  final PreferenceService _prefService;

  BaseCurrencyNotifier(this._prefService) : super(_prefService.baseCurrency);

  Future<void> setCurrency(String newCurrency) async {
    await _prefService.setBaseCurrency(newCurrency);
    state = newCurrency;
  }
}

final baseCurrencyProvider = StateNotifierProvider<BaseCurrencyNotifier, String>((ref) {
  final prefService = ref.watch(preferenceServiceProvider);
  return BaseCurrencyNotifier(prefService);
});
