import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../auth_provider.dart';
import '../../../core/services/local_auth_service.dart';

class BiometricsSetupPage extends ConsumerWidget {
  const BiometricsSetupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localAuth = ref.watch(localAuthServiceProvider);
    final authNotifier = ref.read(authProvider.notifier);

    Future<void> enableBiometrics() async {
      final success = await localAuth.authenticate(
        localizedReason: 'Verify your identity to enable biometric unlock',
      );

      if (success) {
        await authNotifier.setBiometricsEnabled(true);
      }
      authNotifier.authenticateSession(true);
    }

    void skipBiometrics() {
      authNotifier.authenticateSession(true);
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.fingerprint_rounded,
                      size: 70,
                      color: AppTheme.emeraldGreen,
                    ),
                    Positioned(
                      bottom: 24,
                      right: 24,
                      child: Icon(
                        Icons.face_unlock_rounded,
                        size: 32,
                        color: AppTheme.neonBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Enable Biometrics?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Use fingerprint or face recognition for fast and secure access to your account without typing your PIN.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.5),
              ),
              const Spacer(),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: enableBiometrics,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fingerprint_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Enable Biometrics'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: skipBiometrics,
                    child: const Text('Skip for now'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
