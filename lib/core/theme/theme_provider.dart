import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/preference_service.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
    final PreferenceService _prefService;

    ThemeNotifier(this._prefService) : super(ThemeMode.dark) {
        _loadTheme();
    }

    void _loadTheme() {
        final isDark = _prefService.isDarkMode;
        state = isDark ? ThemeMode.dark : ThemeMode.light;
    }

    Future<void> toggleTheme() async {
        if (state == ThemeMode.dark) {
            state = ThemeMode.light;
            await _prefService.setDarkMode(false);
        } else {
            state = ThemeMode.dark;
            await _prefService.setDarkMode(true);
        }
    }

    bool get isDarkMode => state == ThemeMode.dark;
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
    final prefService = ref.watch(preferenceServiceProvider);
    return ThemeNotifier(prefService);
});
