import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'number_format_service.dart';

class PreferenceService {
  final SharedPreferences _prefs;

  PreferenceService(this._prefs);

  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyBiometricsEnabled = 'biometrics_enabled';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyPrivacyMode = 'privacy_mode';
  static const String _keyBaseCurrency = 'base_currency';
  static const String _keyAutoLock = 'auto_lock_background';
  static const String _keyFontFamily = 'app_font_family';
  static const String _keyNumberSeparatorFormat = 'number_separator_format';
  static const String _keyDecimalDigits = 'decimal_digits';
  static const String _keyCurrencySpacing = 'currency_spacing';
  static const String _keyUserName = 'user_display_name';
  static const String _keyUserEmail = 'user_email_address';
  static const String _keyUserProfileImage = 'user_profile_image_path';

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
      _prefs.getBool(_keyThemeMode) ?? true; // Default to dark mode

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

  bool get isAutoLockEnabled =>
      _prefs.getBool(_keyAutoLock) ?? false;

  Future<void> setAutoLockEnabled(bool enabled) async {
    await _prefs.setBool(_keyAutoLock, enabled);
  }

  String get fontFamily =>
      _prefs.getString(_keyFontFamily) ?? 'Outfit';

  Future<void> setFontFamily(String font) async {
    await _prefs.setString(_keyFontFamily, font);
  }

  NumberSeparatorFormat get numberSeparatorFormat =>
      NumberSeparatorFormatExtension.fromId(
        _prefs.getString(_keyNumberSeparatorFormat) ?? 'commaDot',
      );

  Future<void> setNumberSeparatorFormat(NumberSeparatorFormat format) async {
    await _prefs.setString(_keyNumberSeparatorFormat, format.id);
  }

  int get decimalDigits =>
      _prefs.getInt(_keyDecimalDigits) ?? 2;

  Future<void> setDecimalDigits(int digits) async {
    await _prefs.setInt(_keyDecimalDigits, digits);
  }

  bool get isCurrencySpacingEnabled =>
      _prefs.getBool(_keyCurrencySpacing) ?? true;

  Future<void> setCurrencySpacingEnabled(bool enabled) async {
    await _prefs.setBool(_keyCurrencySpacing, enabled);
  }

  String get userName =>
      _prefs.getString(_keyUserName) ?? 'Sandaruwan B.';

  Future<void> setUserName(String name) async {
    await _prefs.setString(_keyUserName, name);
  }

  String get userEmail =>
      _prefs.getString(_keyUserEmail) ?? 'sandaruwan@finex.vault';

  Future<void> setUserEmail(String email) async {
    await _prefs.setString(_keyUserEmail, email);
  }

  String get userProfileImage =>
      _prefs.getString(_keyUserProfileImage) ?? '';

  Future<void> setUserProfileImage(String path) async {
    await _prefs.setString(_keyUserProfileImage, path);
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

class AutoLockNotifier extends StateNotifier<bool> {
  final PreferenceService _prefService;

  AutoLockNotifier(this._prefService) : super(_prefService.isAutoLockEnabled);

  Future<void> toggleAutoLock() async {
    final newState = !state;
    await _prefService.setAutoLockEnabled(newState);
    state = newState;
  }
}

final autoLockProvider = StateNotifierProvider<AutoLockNotifier, bool>((ref) {
  final prefService = ref.watch(preferenceServiceProvider);
  return AutoLockNotifier(prefService);
});

class FontFamilyNotifier extends StateNotifier<String> {
  final PreferenceService _prefService;

  FontFamilyNotifier(this._prefService) : super(_prefService.fontFamily);

  Future<void> setFontFamily(String font) async {
    await _prefService.setFontFamily(font);
    state = font;
  }
}

final fontFamilyProvider = StateNotifierProvider<FontFamilyNotifier, String>((ref) {
  final prefService = ref.watch(preferenceServiceProvider);
  return FontFamilyNotifier(prefService);
});

class NumberSeparatorFormatNotifier extends StateNotifier<NumberSeparatorFormat> {
  final PreferenceService _prefService;

  NumberSeparatorFormatNotifier(this._prefService) : super(_prefService.numberSeparatorFormat);

  Future<void> setFormat(NumberSeparatorFormat format) async {
    await _prefService.setNumberSeparatorFormat(format);
    state = format;
  }
}

final numberSeparatorFormatProvider = StateNotifierProvider<NumberSeparatorFormatNotifier, NumberSeparatorFormat>((ref) {
  final prefService = ref.watch(preferenceServiceProvider);
  return NumberSeparatorFormatNotifier(prefService);
});

class DecimalDigitsNotifier extends StateNotifier<int> {
  final PreferenceService _prefService;

  DecimalDigitsNotifier(this._prefService) : super(_prefService.decimalDigits);

  Future<void> setDigits(int digits) async {
    await _prefService.setDecimalDigits(digits);
    state = digits;
  }
}

final decimalDigitsProvider = StateNotifierProvider<DecimalDigitsNotifier, int>((ref) {
  final prefService = ref.watch(preferenceServiceProvider);
  return DecimalDigitsNotifier(prefService);
});

class CurrencySpacingNotifier extends StateNotifier<bool> {
  final PreferenceService _prefService;

  CurrencySpacingNotifier(this._prefService) : super(_prefService.isCurrencySpacingEnabled);

  Future<void> toggleSpacing(bool enabled) async {
    await _prefService.setCurrencySpacingEnabled(enabled);
    state = enabled;
  }
}

final currencySpacingProvider = StateNotifierProvider<CurrencySpacingNotifier, bool>((ref) {
  final prefService = ref.watch(preferenceServiceProvider);
  return CurrencySpacingNotifier(prefService);
});

// --- User Profile State ---

class UserProfile {
  final String name;
  final String email;
  final String? imagePath;

  const UserProfile({
    required this.name,
    required this.email,
    this.imagePath,
  });

  String get initials {
    final clean = name.trim();
    if (clean.isEmpty) return 'U';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(1, 2)).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? imagePath,
    bool clearImage = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  final PreferenceService _prefService;

  UserProfileNotifier(this._prefService)
      : super(UserProfile(
          name: _prefService.userName,
          email: _prefService.userEmail,
          imagePath: _prefService.userProfileImage.isEmpty ? null : _prefService.userProfileImage,
        ));

  Future<void> updateProfile({
    required String name,
    required String email,
    String? imagePath,
    bool clearImage = false,
  }) async {
    await _prefService.setUserName(name);
    await _prefService.setUserEmail(email);
    if (clearImage) {
      await _prefService.setUserProfileImage('');
    } else if (imagePath != null) {
      await _prefService.setUserProfileImage(imagePath);
    }
    state = state.copyWith(
      name: name,
      email: email,
      imagePath: imagePath,
      clearImage: clearImage,
    );
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  final prefService = ref.watch(preferenceServiceProvider);
  return UserProfileNotifier(prefService);
});
