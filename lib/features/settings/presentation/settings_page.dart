import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/main_drawer.dart';
import '../../auth/auth_provider.dart';
import '../../../core/services/local_auth_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _toggleBiometrics(bool enabled) async {
    final authNotifier = ref.read(authProvider.notifier);
    if (enabled) {
      final localAuth = ref.read(localAuthServiceProvider);
      final canAuth = await localAuth.canAuthenticate;
      if (canAuth) {
        final success = await localAuth.authenticate(
          localizedReason: 'Authenticate to enable biometric unlock',
        );
        if (success) {
          await authNotifier.setBiometricsEnabled(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometrics are not set up or supported on this device.'),
            ),
          );
        }
      }
    } else {
      await authNotifier.setBiometricsEnabled(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const MainDrawer(activeRoute: '/settings'),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Profile Card Preview
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161C2A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
                    child: Text(
                      'AM',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alex Morgan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'alex.morgan@finex.app',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Settings Groups
            _buildSectionTitle('PREFERENCES'),
            const SizedBox(height: 8),
            _buildSettingCard([
              SwitchListTile(
                value: isDark,
                onChanged: (val) {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
                secondary: const Icon(Icons.dark_mode_rounded),
                title: const Text('Dark Mode Theme'),
                subtitle: const Text('Switch interface appearance'),
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionTitle('SECURITY'),
            const SizedBox(height: 8),
            _buildSettingCard([
              SwitchListTile(
                value: authState.isBiometricsEnabled,
                onChanged: _toggleBiometrics,
                secondary: const Icon(Icons.fingerprint_rounded),
                title: const Text('Biometric Authentication'),
                subtitle: const Text('Unlock app using Fingerprint / Face ID'),
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.password_rounded),
                title: const Text('Change Lock PIN'),
                subtitle: const Text('Update your local security code'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  // Direct to PIN update/setup screen
                  context.push('/pin-setup');
                },
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionTitle('SYSTEM'),
            const SizedBox(height: 8),
            _buildSettingCard([
              ListTile(
                leading: const Icon(Icons.lock_reset_rounded, color: AppTheme.goldAccent),
                title: const Text('Lock App Now'),
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                },
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: AppTheme.dangerRed),
                title: const Text(
                  'Reset App Data',
                  style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Erase all stored keys and configurations'),
                onTap: () {
                  _showResetDialog(context);
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161C2A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset App Data?'),
        content: const Text(
          'This developer shortcut will erase the stored PIN, onboarding completion state, and biometrics flags. The app will return to the onboarding screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).resetAll();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }
}
