import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finex/core/services/preference_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserProfile & PreferenceService Profile Tests', () {
    late SharedPreferences prefs;
    late PreferenceService prefService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      prefService = PreferenceService(prefs);
    });

    test('Default user profile values', () {
      expect(prefService.userName, 'Sandaruwan B.');
      expect(prefService.userEmail, 'sandaruwan@finex.vault');
      expect(prefService.userProfileImage, '');
    });

    test('Updating user profile values persists to SharedPreferences', () async {
      await prefService.setUserName('Nimal Silva');
      await prefService.setUserEmail('nimal@finex.vault');
      await prefService.setUserProfileImage('/path/to/avatar.png');

      expect(prefService.userName, 'Nimal Silva');
      expect(prefService.userEmail, 'nimal@finex.vault');
      expect(prefService.userProfileImage, '/path/to/avatar.png');
    });

    test('UserProfile initials computation handles single and multi-word names', () {
      const p1 = UserProfile(name: 'Sandaruwan Bandara', email: 's@finex.app');
      expect(p1.initials, 'SB');

      const p2 = UserProfile(name: 'Sandaruwan', email: 's@finex.app');
      expect(p2.initials, 'SA');

      const p3 = UserProfile(name: 'A B C', email: 'a@finex.app');
      expect(p3.initials, 'AB');

      const p4 = UserProfile(name: '', email: 'empty@finex.app');
      expect(p4.initials, 'U');
    });
  });
}
