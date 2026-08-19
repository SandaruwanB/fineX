import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finex/core/services/preference_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreferenceService Tests', () {
    late SharedPreferences prefs;
    late PreferenceService preferenceService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'onboarding_completed': false,
        'biometrics_enabled': false,
      });
      prefs = await SharedPreferences.getInstance();
      preferenceService = PreferenceService(prefs);
    });

    test('initial states should be false', () {
      expect(preferenceService.isOnboardingCompleted, isFalse);
      expect(preferenceService.isBiometricsEnabled, isFalse);
    });

    test('setting onboarding status should persist', () async {
      await preferenceService.setOnboardingCompleted(true);
      expect(preferenceService.isOnboardingCompleted, isTrue);

      // Verify directly from shared preferences
      expect(prefs.getBool('onboarding_completed'), isTrue);
    });

    test('setting biometrics toggle should persist', () async {
      await preferenceService.setBiometricsEnabled(true);
      expect(preferenceService.isBiometricsEnabled, isTrue);

      // Verify directly from shared preferences
      expect(prefs.getBool('biometrics_enabled'), isTrue);
    });
  });
}
