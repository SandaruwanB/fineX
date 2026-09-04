import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../../features/auth/auth_provider.dart';
import '../services/preference_service.dart';

class MainDrawer extends ConsumerWidget {
    final String activeRoute;

    const MainDrawer({super.key, required this.activeRoute});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final themeMode = ref.watch(themeProvider);
        final isDark = themeMode == ThemeMode.dark;
        final authNotifier = ref.read(authProvider.notifier);
        final userProfile = ref.watch(userProfileProvider);

        return Drawer(
            backgroundColor: isDark ? const Color(0xFF0D121F) : const Color(0xFFF8FAFC),
            child: Column(
                children: [
                    // Premium Executive Profile Header
                    Container(
                        width: double.infinity,
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 20,
                            left: 20,
                            right: 20,
                            bottom: 22,
                        ),
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: isDark
                                    ? [const Color(0xFF141C2E), const Color(0xFF0F172A)]
                                    : [AppTheme.lightPrimary, const Color(0xFF1E293B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                            ),
                            border: Border(
                                bottom: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFE2E8F0).withValues(alpha: 0.1),
                                ),
                            ),
                        ),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                                // Dual-ring Avatar with Emerald Glow
                                Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppTheme.emeraldGreen, width: 2),
                                        boxShadow: [
                                            BoxShadow(
                                                color: AppTheme.emeraldGreen.withValues(alpha: 0.25),
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                            ),
                                        ],
                                    ),
                                    child: CircleAvatar(
                                        backgroundColor: const Color(0xFF1E293B),
                                        backgroundImage: userProfile.imagePath != null &&
                                                userProfile.imagePath!.isNotEmpty &&
                                                File(userProfile.imagePath!).existsSync()
                                            ? FileImage(File(userProfile.imagePath!))
                                            : null,
                                        child: (userProfile.imagePath != null &&
                                                userProfile.imagePath!.isNotEmpty &&
                                                File(userProfile.imagePath!).existsSync())
                                            ? null
                                            : Text(
                                                userProfile.initials,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 17,
                                                ),
                                            ),
                                    ),
                                ),
                                const SizedBox(width: 14),

                                // Name & Verified Email Column
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                            Row(
                                                children: [
                                                    Flexible(
                                                        child: Text(
                                                            userProfile.name,
                                                            style: const TextStyle(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.w800,
                                                                fontSize: 16,
                                                                letterSpacing: -0.3,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                        ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                        decoration: BoxDecoration(
                                                            color: AppTheme.wealthGreen.withValues(alpha: 0.2),
                                                            borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: const Text(
                                                            'PRO',
                                                            style: TextStyle(
                                                                color: AppTheme.emeraldGreen,
                                                                fontSize: 8,
                                                                fontWeight: FontWeight.w900,
                                                                letterSpacing: 0.5,
                                                            ),
                                                        ),
                                                    ),
                                                ],
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                                children: [
                                                    Icon(
                                                        Icons.verified_user_rounded,
                                                        size: 12,
                                                        color: AppTheme.emeraldGreen.withValues(alpha: 0.9),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                        child: Text(
                                                            userProfile.email,
                                                            style: TextStyle(
                                                                color: Colors.white.withValues(alpha: 0.7),
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w500,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                        ),
                                                    ),
                                                ],
                                            ),
                                        ],
                                    ),
                                ),
                            ],
                        ),
                    ),

                    // Navigation Menu (Categorized)
                    Expanded(
                        child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            physics: const BouncingScrollPhysics(),
                            children: [
                                _buildSectionHeader('CORE PORTFOLIO'),
                                const SizedBox(height: 6),
                                _buildDrawerItem(
                                    context: context,
                                    icon: Icons.grid_view_rounded,
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
                                    title: 'Categories',
                                    route: '/categories',
                                    isActive: activeRoute == '/categories',
                                ),

                                const SizedBox(height: 18),
                                _buildSectionHeader('INTELLIGENCE & AUDIT'),
                                const SizedBox(height: 6),
                                _buildDrawerItem(
                                    context: context,
                                    icon: Icons.query_stats_rounded,
                                    title: 'Cash Flow Analytics',
                                    route: '/analytics',
                                    isActive: activeRoute == '/analytics',
                                ),
                                _buildDrawerItem(
                                    context: context,
                                    icon: Icons.history_rounded,
                                    title: 'Transaction History',
                                    route: '/transactions',
                                    isActive: activeRoute == '/transactions' || activeRoute == '/tax',
                                ),

                                const SizedBox(height: 18),
                                _buildSectionHeader('PREFERENCES'),
                                const SizedBox(height: 6),
                                _buildDrawerItem(
                                    context: context,
                                    icon: Icons.settings_rounded,
                                    title: 'Settings',
                                    route: '/settings',
                                    isActive: activeRoute == '/settings',
                                ),

                                const SizedBox(height: 12),
                                // Sleek Dark Mode Switcher Card
                                Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF131A29) : Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                        ),
                                    ),
                                    child: Row(
                                        children: [
                                            Container(
                                                padding: const EdgeInsets.all(7),
                                                decoration: BoxDecoration(
                                                    color: (isDark ? AppTheme.emeraldGreen : AppTheme.lightPrimary).withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                                    size: 18,
                                                    color: isDark ? AppTheme.emeraldGreen : AppTheme.lightPrimary,
                                                ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                                child: Text(
                                                    'Dark Mode',
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w700,
                                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                    ),
                                                ),
                                            ),
                                            Switch.adaptive(
                                                value: isDark,
                                                activeTrackColor: AppTheme.emeraldGreen,
                                                onChanged: (val) {
                                                    ref.read(themeProvider.notifier).toggleTheme();
                                                },
                                            ),
                                        ],
                                    ),
                                ),
                            ],
                        ),
                    ),

                    // Executive Bottom Session & Signature Section
                    SafeArea(
                        top: false,
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                            child: Column(
                                children: [
                                    // Security Lock Card
                                    Material(
                                        color: isDark ? const Color(0xFF131A29) : Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                            side: BorderSide(
                                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                            ),
                                        ),
                                        child: InkWell(
                                            borderRadius: BorderRadius.circular(14),
                                            onTap: () {
                                                Navigator.pop(context);
                                                authNotifier.logout();
                                            },
                                            child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                child: Row(
                                                    children: [
                                                        Container(
                                                            padding: const EdgeInsets.all(7),
                                                            decoration: BoxDecoration(
                                                                color: AppTheme.goldAccent.withValues(alpha: 0.12),
                                                                borderRadius: BorderRadius.circular(10),
                                                            ),
                                                            child: const Icon(
                                                                Icons.lock_rounded,
                                                                size: 18,
                                                                color: AppTheme.goldAccent,
                                                            ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                            child: Text(
                                                                'Lock Wallet',
                                                                style: TextStyle(
                                                                    fontSize: 13,
                                                                    fontWeight: FontWeight.w800,
                                                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                                ),
                                                            ),
                                                        ),
                                                        Icon(
                                                            Icons.chevron_right_rounded,
                                                            size: 18,
                                                            color: isDark ? Colors.white38 : Colors.black38,
                                                        ),
                                                    ],
                                                ),
                                            ),
                                        ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Version & Developer Signature
                                    Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                            Text(
                                                'fineX v1.0.0',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark ? Colors.white38 : Colors.black45,
                                                    letterSpacing: 0.4,
                                                ),
                                            ),
                                        ],
                                    ),
                                    const SizedBox(height: 4),
                                    InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () async {
                                            final uri = Uri.parse('https://www.linkedin.com/in/sandaruwan-bandara/');
                                            try {
                                                final launched = await launchUrl(
                                                    uri,
                                                    mode: LaunchMode.externalApplication,
                                                );
                                                if (!launched) {
                                                    await launchUrl(
                                                        uri,
                                                        mode: LaunchMode.platformDefault,
                                                    );
                                                }
                                            } catch (_) {
                                                try {
                                                    await launchUrl(
                                                        uri,
                                                        mode: LaunchMode.inAppBrowserView,
                                                    );
                                                } catch (_) {}
                                            }
                                        },
                                        child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            child: RichText(
                                                text: TextSpan(
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: isDark ? Colors.white54 : Colors.black54,
                                                    ),
                                                    children: const [
                                                        TextSpan(text: 'Developed with ❤️ by '),
                                                        TextSpan(
                                                            text: 'Sandy',
                                                            style: TextStyle(
                                                                fontWeight: FontWeight.w800,
                                                                color: AppTheme.emeraldGreen,
                                                                decoration: TextDecoration.underline,
                                                                decorationColor: AppTheme.emeraldGreen,
                                                            ),
                                                        ),
                                                    ],
                                                ),
                                            ),
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

    Widget _buildSectionHeader(String title) {
        return Padding(
            padding: const EdgeInsets.only(left: 6.0, bottom: 4.0),
            child: Text(
                title,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.grey,
                ),
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

        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: Material(
                color: isActive
                    ? (isDark ? const Color(0xFF132328) : const Color(0xFFECFDF5))
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isActive
                        ? BorderSide(color: AppTheme.emeraldGreen.withValues(alpha: 0.35))
                        : BorderSide.none,
                ),
                child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                        Navigator.pop(context);
                        if (!isActive) {
                            context.go(route);
                        }
                    },
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                            children: [
                                Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                        color: isActive
                                            ? AppTheme.wealthGreen.withValues(alpha: 0.18)
                                            : (isDark ? const Color(0xFF161C2A) : const Color(0xFFEDF2F7)),
                                        borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                        icon,
                                        size: 18,
                                        color: isActive
                                            ? AppTheme.emeraldGreen
                                            : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                    ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(
                                        title,
                                        style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                                            color: isActive
                                                ? (isDark ? Colors.white : AppTheme.emeraldGreen)
                                                : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                        ),
                                    ),
                                ),
                                if (isActive)
                                    Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                            color: AppTheme.emeraldGreen,
                                            shape: BoxShape.circle,
                                        ),
                                    ),
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}
