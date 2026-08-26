import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../../features/auth/auth_provider.dart';

class MainDrawer extends ConsumerWidget {
  final String activeRoute;

  const MainDrawer({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final authNotifier = ref.read(authProvider.notifier);

    return Drawer(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      child: Column(
        children: [
          // Drawer Header with User Profile details
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF161C2A), const Color(0xFF0F172A)]
                    : [AppTheme.lightPrimary, const Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.emeraldGreen, width: 2),
              ),
              child: const CircleAvatar(
                backgroundColor: Color(0xFF1E293B),
                child: Text(
                  'AM',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            accountName: const Text(
              'Alex Morgan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: const Text(
              'alex.morgan@finex.app',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),

          // Drawer Body List Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  route: '/dashboard',
                  isActive: activeRoute == '/dashboard',
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Manage Accounts',
                  route: '/accounts',
                  isActive: activeRoute == '/accounts',
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.category_rounded,
                  title: 'Expense Categories',
                  route: '/categories',
                  isActive: activeRoute == '/categories',
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.analytics_rounded,
                  title: 'Cash Flow Analytics',
                  route: '/analytics',
                  isActive: activeRoute == '/analytics',
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  route: '/settings',
                  isActive: activeRoute == '/settings',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(height: 1),
                ),
                
                // Theme Toggle Tile
                SwitchListTile(
                  secondary: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: isDark ? AppTheme.emeraldGreen : AppTheme.lightPrimary,
                  ),
                  title: const Text(
                    'Dark Mode',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  value: isDark,
                  onChanged: (val) {
                    ref.read(themeProvider.notifier).toggleTheme();
                  },
                ),
              ],
            ),
          ),

          // Drawer Footer Section
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Divider(),
                  // Lock Button
                  ListTile(
                    leading: const Icon(Icons.lock_rounded, color: AppTheme.goldAccent),
                    title: const Text(
                      'Lock Wallet',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close Drawer
                      authNotifier.logout();  // Reset session authentication
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // Reset Button (Dev Action)
                  ListTile(
                    leading: const Icon(Icons.restart_alt_rounded, color: AppTheme.dangerRed),
                    title: const Text(
                      'Reset All Data',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close Drawer
                      _showResetDialog(context, authNotifier);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    required bool isActive,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isActive
            ? AppTheme.emeraldGreen
            : (isDark ? Colors.white70 : Colors.black87),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive
              ? AppTheme.emeraldGreen
              : (isDark ? Colors.white : Colors.black87),
        ),
      ),
      selected: isActive,
      selectedTileColor: AppTheme.emeraldGreen.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: () {
        Navigator.pop(context); // Close Drawer
        if (!isActive) {
          context.go(route);
        }
      },
    );
  }

  void _showResetDialog(BuildContext context, AuthNotifier authNotifier) {
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
              authNotifier.resetAll();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }
}
