import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthService {
  final LocalAuthentication _auth;

  LocalAuthService(this._auth);

  /// Check if the device has biometric hardware capable of scanning.
  Future<bool> get isDeviceSupported async => await _auth.isDeviceSupported();

  /// Check if any biometrics (Fingerprint/Face ID) are enrolled on the device.
  Future<bool> get canAuthenticate async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!isSupported || !canCheck) return false;

      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Triggers biometric authentication.
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Get the list of available biometric types on this device (e.g. fingerprint, face, weak, strong)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return <BiometricType>[];
    }
  }
}

final localAuthenticationProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

final localAuthServiceProvider = Provider<LocalAuthService>((ref) {
  final auth = ref.watch(localAuthenticationProvider);
  return LocalAuthService(auth);
});
