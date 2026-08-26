import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../auth_provider.dart';
import '../../../core/services/local_auth_service.dart';

class PinSetupPage extends ConsumerStatefulWidget {
  const PinSetupPage({super.key});

  @override
  ConsumerState<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends ConsumerState<PinSetupPage> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String _errorMessage = '';

  void _onKeyPress(String val) {
    setState(() {
      _errorMessage = '';
      if (_isConfirming) {
        if (_confirmPin.length < 4) {
          _confirmPin += val;
        }
        if (_confirmPin.length == 4) {
          _verifyAndSave();
        }
      } else {
        if (_pin.length < 4) {
          _pin += val;
        }
        if (_pin.length == 4) {
          Future.delayed(const Duration(milliseconds: 250), () {
            setState(() {
              _isConfirming = true;
            });
          });
        }
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _errorMessage = '';
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  Future<void> _verifyAndSave() async {
    if (_pin == _confirmPin) {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.savePin(_pin);

      final localAuth = ref.read(localAuthServiceProvider);
      final hasHardware = await localAuth.isDeviceSupported;
      final canAuth = await localAuth.canAuthenticate;

      if (hasHardware && canAuth && mounted) {
        context.go('/biometrics-setup');
      } else {
        authNotifier.authenticateSession(true);
      }
    } else {
      setState(() {
        _confirmPin = '';
        _errorMessage = 'PINs do not match. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isConfirming ? 'Confirm your PIN' : 'Create a PIN';
    final subtitle = _isConfirming
        ? 'Re-enter your 4-digit PIN to confirm.'
        : 'Secure your financial data with a local code.';
    final currentInput = _isConfirming ? _confirmPin : _pin;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppTheme.emeraldGreen,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < currentInput.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? AppTheme.emeraldGreen
                        : Theme.of(context).colorScheme.outlineVariant,
                    border: Border.all(
                      color: isFilled
                          ? AppTheme.emeraldGreen
                          : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            Container(
              height: 40,
              alignment: Alignment.center,
              child: _errorMessage.isNotEmpty
                  ? Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: AppTheme.dangerRed,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : null,
            ),
            const Spacer(flex: 1),

            Padding(
              padding: const EdgeInsets.only(bottom: 24, left: 32, right: 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [_buildKey('1'), _buildKey('2'), _buildKey('3')],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [_buildKey('4'), _buildKey('5'), _buildKey('6')],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [_buildKey('7'), _buildKey('8'), _buildKey('9')],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _isConfirming
                          ? _buildActionButton(
                              icon: Icons.arrow_back_rounded,
                              onPressed: () {
                                setState(() {
                                  _isConfirming = false;
                                  _confirmPin = '';
                                  _pin = '';
                                });
                              },
                            )
                          : const SizedBox(width: 80, height: 80),
                      _buildKey('0'),
                      _buildActionButton(
                        icon: Icons.backspace_outlined,
                        onPressed: _onBackspace,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _onKeyPress(value),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          shape: BoxShape.circle,
        ),
        child: Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 26,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
