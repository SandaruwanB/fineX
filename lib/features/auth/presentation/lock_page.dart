import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../auth_provider.dart';
import '../../../core/services/local_auth_service.dart';

class LockPage extends ConsumerStatefulWidget {
  const LockPage({super.key});

  @override
  ConsumerState<LockPage> createState() => _LockPageState();
}

class _LockPageState extends ConsumerState<LockPage> {
  String _enteredPin = '';
  String _errorMessage = '';
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoBiometricAuth();
    });
  }

  Future<void> _autoBiometricAuth() async {
    final state = ref.read(authProvider);
    if (state.isBiometricsEnabled) {
      await _authenticateWithBiometrics();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = '';
    });

    final localAuth = ref.read(localAuthServiceProvider);
    final success = await localAuth.authenticate(
      localizedReason: 'Authenticate to unlock fineX',
    );

    if (success) {
      ref.read(authProvider.notifier).authenticateSession(true);
    } else {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  void _onKeyPress(String val) {
    if (_enteredPin.length >= 4) return;

    setState(() {
      _errorMessage = '';
      _enteredPin += val;
      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    });
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _errorMessage = '';
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    final success = await ref
        .read(authProvider.notifier)
        .verifyPin(_enteredPin);
    if (!success) {
      setState(() {
        _enteredPin = '';
        _errorMessage = 'Incorrect PIN. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

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
                      Icons.lock_person_rounded,
                      color: AppTheme.emeraldGreen,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome back',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock your finance vault.',
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
                final isFilled = index < _enteredPin.length;
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
                      state.isBiometricsEnabled
                          ? _buildActionButton(
                              icon: Icons.fingerprint_rounded,
                              onPressed: _authenticateWithBiometrics,
                              color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                              iconColor: AppTheme.emeraldGreen,
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
    Color? color,
    Color? iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFE2E8F0);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color ?? defaultBg,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 26,
          color: iconColor ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
