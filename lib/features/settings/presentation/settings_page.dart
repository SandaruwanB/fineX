import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/main_drawer.dart';
import '../../../core/widgets/drawer_blur_wrapper.dart';
import '../../auth/auth_provider.dart';
import '../../../core/services/local_auth_service.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/preference_service.dart';
import '../../../core/services/number_format_service.dart';
import '../../../core/constants/currencies.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;

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
    final baseCurrency = ref.watch(baseCurrencyProvider);
    final isAutoLockEnabled = ref.watch(autoLockProvider);
    final currentFont = ref.watch(fontFamilyProvider);
    final separatorFormat = ref.watch(numberSeparatorFormatProvider);
    final decimalDigits = ref.watch(decimalDigitsProvider);
    final isCurrencySpacingEnabled = ref.watch(currencySpacingProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dashboard');
          }
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const MainDrawer(activeRoute: '/settings'),
        drawerScrimColor: (isDark ? Colors.black : const Color(0xFF0F172A)).withValues(alpha: 0.45),
        onDrawerChanged: (isOpen) {
          if (_isDrawerOpen != isOpen) {
            setState(() => _isDrawerOpen = isOpen);
          }
        },
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
          title: const Text('Settings'),
        ),
      body: DrawerBlurWrapper(
        isDrawerOpen: _isDrawerOpen,
        child: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            // Minimal Google Style Profile Header
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
                    radius: 26,
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    child: Text(
                      'SB',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Sandaruwan B.',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'sandaruwan@finex.vault',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Typography & Visuals
            _buildSectionTitle('APPEARANCE & TYPOGRAPHY'),
            const SizedBox(height: 10),
            _buildSettingCard(isDark, [
              SwitchListTile(
                value: isDark,
                activeTrackColor: AppTheme.emeraldGreen,
                onChanged: (val) {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
                secondary: _buildSettingIcon(Icons.dark_mode_rounded, AppTheme.neonBlue, isDark),
                title: const Text('Dark Mode Appearance', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('Minimalist slate dark appearance', style: TextStyle(fontSize: 12)),
              ),
              Divider(height: 1, color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              ListTile(
                leading: _buildSettingIcon(Icons.text_fields_rounded, AppTheme.purpleAccent, isDark),
                title: const Text('App Font Style', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Text('Current: $currentFont', style: const TextStyle(fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currentFont,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? AppTheme.emeraldGreen : AppTheme.lightPrimary),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                  ],
                ),
                onTap: () => _showFontPickerDialog(context),
              ),
            ]),
            const SizedBox(height: 24),

            // Currency & Number Formatting
            _buildSectionTitle('CURRENCY & NUMBER FORMATTING'),
            const SizedBox(height: 10),
            _buildSettingCard(isDark, [
              ListTile(
                leading: _buildSettingIcon(Icons.monetization_on_rounded, AppTheme.goldAccent, isDark),
                title: const Text('Base Currency', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Text('Current: $baseCurrency (${worldCurrencies[baseCurrency] ?? ''})', style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                onTap: () => _showCurrencyPickerDialog(context),
              ),
              Divider(height: 1, color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              ListTile(
                leading: _buildSettingIcon(Icons.format_list_numbered_rounded, AppTheme.neonBlue, isDark),
                title: const Text('Number & Separator Format', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Text(
                  separatorFormat.title,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                onTap: () => _showNumberFormatPickerDialog(context),
              ),
              Divider(height: 1, color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              ListTile(
                leading: _buildSettingIcon(Icons.pin_outlined, AppTheme.purpleAccent, isDark),
                title: const Text('Decimal Places', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Text(
                  '$decimalDigits Decimals (e.g. ${NumberFormatService.formatAmount(amount: 75000.0, separatorFormat: separatorFormat, decimalDigits: decimalDigits, withSpace: isCurrencySpacingEnabled, currencySymbol: worldCurrencies[baseCurrency])})',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                onTap: () => _showDecimalDigitsDialog(context),
              ),
              Divider(height: 1, color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              SwitchListTile(
                value: isCurrencySpacingEnabled,
                activeTrackColor: AppTheme.emeraldGreen,
                onChanged: (val) {
                  ref.read(currencySpacingProvider.notifier).toggleSpacing(val);
                },
                secondary: _buildSettingIcon(Icons.space_bar_rounded, AppTheme.wealthGreen, isDark),
                title: const Text('Currency Symbol Spacing', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Text(
                  isCurrencySpacingEnabled
                      ? 'Enabled (e.g. ${worldCurrencies[baseCurrency] ?? '\$'} 75,000)'
                      : 'Compact (e.g. ${worldCurrencies[baseCurrency] ?? '\$'}75,000)',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // Security Settings
            _buildSectionTitle('SECURITY & PRIVACY'),
            const SizedBox(height: 10),
            _buildSettingCard(isDark, [
              SwitchListTile(
                value: authState.isBiometricsEnabled,
                activeTrackColor: AppTheme.emeraldGreen,
                onChanged: _toggleBiometrics,
                secondary: _buildSettingIcon(Icons.fingerprint_rounded, AppTheme.emeraldGreen, isDark),
                title: const Text('Biometric Unlock', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('Touch ID / Face ID hardware authentication', style: TextStyle(fontSize: 12)),
              ),
              Divider(height: 1, color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              SwitchListTile(
                value: isAutoLockEnabled,
                activeTrackColor: AppTheme.emeraldGreen,
                onChanged: (val) {
                  ref.read(autoLockProvider.notifier).toggleAutoLock();
                },
                secondary: _buildSettingIcon(Icons.timer_rounded, AppTheme.electricIndigo, isDark),
                title: const Text('Auto-Lock on Background', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('Protect wallet immediately when minimized', style: TextStyle(fontSize: 12)),
              ),
              Divider(height: 1, color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              ListTile(
                leading: _buildSettingIcon(Icons.password_rounded, AppTheme.neonBlue, isDark),
                title: const Text('Change Master PIN', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('Update your local security code', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                onTap: () {
                  _showChangePinDialog(context);
                },
              ),
              Divider(height: 1, color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              ListTile(
                leading: _buildSettingIcon(Icons.shield_rounded, AppTheme.emeraldGreen, isDark),
                title: const Text('Data Security', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('Hardware Encrypted at Rest', style: TextStyle(fontSize: 12)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.4), width: 0.8),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.emeraldGreen,
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // Backup & Data
            _buildSectionTitle('BACKUP & STORAGE'),
            const SizedBox(height: 10),
            _buildSettingCard(isDark, [
              ListTile(
                leading: _buildSettingIcon(Icons.upload_file_rounded, AppTheme.neonBlue, isDark),
                title: const Text('Export Encrypted Backup (.zip)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('Save database current snapshot archive', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                onTap: () async {
                  final success = await BackupService.exportBackup(context);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Backup exported successfully!')),
                    );
                  }
                },
              ),
              Divider(height: 1, color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              ListTile(
                leading: _buildSettingIcon(Icons.file_download_rounded, AppTheme.emeraldGreen, isDark),
                title: const Text('Import / Restore Backup', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('Restore database from an exported zip file', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                onTap: () async {
                  final success = await BackupService.importBackup(context, ref);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Database restored successfully!')),
                    );
                  }
                },
              ),
            ]),
            const SizedBox(height: 24),

            // System Actions
            _buildSectionTitle('SYSTEM ACTIONS'),
            const SizedBox(height: 10),
            _buildSettingCard(isDark, [
              ListTile(
                leading: _buildSettingIcon(Icons.lock_rounded, AppTheme.goldAccent, isDark),
                title: const Text('Lock App Immediately', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                },
              ),
              Divider(height: 1, color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              ListTile(
                leading: _buildSettingIcon(Icons.delete_forever_rounded, AppTheme.dangerRed, isDark),
                title: const Text(
                  'Reset App Data',
                  style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.w800, fontSize: 14),
                ),
                subtitle: const Text('Wipe local database and reset to initial setup', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                onTap: () {
                  _showResetDialog(context);
                },
              ),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
    ));
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildSettingIcon(IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _buildSettingCard(bool isDark, List<Widget> children) {
    return Material(
      color: isDark ? const Color(0xFF161C2A) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }

  void _showFontPickerDialog(BuildContext context) {
    final currentFont = ref.read(fontFamilyProvider);
    final fonts = [
      {
        'id': 'Plus Jakarta Sans',
        'title': 'Plus Jakarta Sans',
        'subtitle': 'Modern Geometric / Google Sans Aesthetic',
        'style': GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800),
      },
      {
        'id': 'Inter',
        'title': 'Inter',
        'subtitle': 'Swiss Precision & Ultra-Clean Minimalism',
        'style': GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
      },
      {
        'id': 'Outfit',
        'title': 'Outfit',
        'subtitle': 'Avant-Garde Geometric & High Fashion Tech',
        'style': GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800),
      },
      {
        'id': 'Poppins',
        'title': 'Poppins',
        'subtitle': 'Rounded Contemporary & Friendly Readability',
        'style': GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161C2A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Choose Typography Style',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Select your preferred typeface to customize the entire app interface.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ...fonts.map((f) {
                  final fontId = f['id'] as String;
                  final isSelected = fontId == currentFont;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: isSelected
                          ? (isDark ? AppTheme.emeraldGreen.withValues(alpha: 0.15) : AppTheme.lightPrimary.withValues(alpha: 0.08))
                          : (isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.emeraldGreen
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        title: Text(f['title'] as String, style: f['style'] as TextStyle),
                        subtitle: Text(f['subtitle'] as String, style: const TextStyle(fontSize: 11)),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreen, size: 22)
                            : const Icon(Icons.circle_outlined, color: Colors.grey, size: 22),
                        onTap: () {
                          ref.read(fontFamilyProvider.notifier).setFontFamily(fontId);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChangePinDialog(BuildContext context) {
    int currentStep = 1; // 1: Old PIN, 2: New PIN, 3: Confirm PIN
    String oldPin = '';
    String newPin = '';
    final pinController = TextEditingController();
    String? errorMessage;
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          String stepTitle;
          String stepSubtitle;
          String buttonText;

          if (currentStep == 1) {
            stepTitle = 'Enter Current PIN';
            stepSubtitle = 'Verify your existing 4-digit Master PIN to proceed';
            buttonText = 'Verify PIN';
          } else if (currentStep == 2) {
            stepTitle = 'Enter New PIN';
            stepSubtitle = 'Choose a new 4-digit security code';
            buttonText = 'Next';
          } else {
            stepTitle = 'Confirm New PIN';
            stepSubtitle = 'Re-enter your new 4-digit PIN to confirm';
            buttonText = 'Update PIN';
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.password_rounded, color: AppTheme.emeraldGreen, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stepTitle,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                      Text(
                        'Step $currentStep of 3',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.emeraldGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stepSubtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    autofocus: true,
                    style: const TextStyle(
                      letterSpacing: 10,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      hintStyle: const TextStyle(letterSpacing: 10),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: errorMessage != null
                              ? AppTheme.dangerRed
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: errorMessage != null ? AppTheme.dangerRed : AppTheme.emeraldGreen,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (_) {
                      if (errorMessage != null) {
                        setDialogState(() => errorMessage = null);
                      }
                    },
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 16, color: AppTheme.dangerRed),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.dangerRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        final entered = pinController.text.trim();
                        if (entered.length != 4) {
                          setDialogState(() {
                            errorMessage = 'Please enter a valid 4-digit code.';
                          });
                          return;
                        }

                        if (currentStep == 1) {
                          // Step 1: Verify Old PIN
                          setDialogState(() {
                            isProcessing = true;
                            errorMessage = null;
                          });
                          final isValid = await ref.read(authProvider.notifier).checkCurrentPin(entered);
                          if (!isValid) {
                            setDialogState(() {
                              isProcessing = false;
                              errorMessage = 'Incorrect current PIN. Please try again.';
                            });
                            return;
                          }
                          oldPin = entered;
                          pinController.clear();
                          setDialogState(() {
                            isProcessing = false;
                            currentStep = 2;
                            errorMessage = null;
                          });
                        } else if (currentStep == 2) {
                          // Step 2: Enter New PIN
                          if (entered == oldPin) {
                            setDialogState(() {
                              errorMessage = 'New PIN must be different from the old PIN.';
                            });
                            return;
                          }
                          newPin = entered;
                          pinController.clear();
                          setDialogState(() {
                            currentStep = 3;
                            errorMessage = null;
                          });
                        } else if (currentStep == 3) {
                          // Step 3: Confirm New PIN
                          if (entered != newPin) {
                            setDialogState(() {
                              errorMessage = 'PINs do not match. Please re-enter.';
                            });
                            return;
                          }
                          setDialogState(() {
                            isProcessing = true;
                            errorMessage = null;
                          });

                          await ref.read(authProvider.notifier).savePin(newPin);

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreen, size: 20),
                                    SizedBox(width: 8),
                                    Text('Master PIN updated successfully!'),
                                  ],
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                child: isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        buttonText,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pinController = TextEditingController();
    String? errorMessage;
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Reset All Data',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This action cannot be undone. All transactions, accounts, categories, and settings will be permanently wiped.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'ENTER YOUR PIN TO CONFIRM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    autofocus: true,
                    style: const TextStyle(
                      letterSpacing: 8,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      hintStyle: const TextStyle(letterSpacing: 8),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: errorMessage != null
                              ? AppTheme.dangerRed
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: errorMessage != null ? AppTheme.dangerRed : AppTheme.emeraldGreen,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    ),
                    onChanged: (_) {
                      if (errorMessage != null) {
                        setDialogState(() {
                          errorMessage = null;
                        });
                      }
                    },
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppTheme.dangerRed, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.dangerRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        final enteredPin = pinController.text.trim();
                        if (enteredPin.length != 4) {
                          setDialogState(() {
                            errorMessage = 'Please enter your 4-digit PIN.';
                          });
                          return;
                        }
                        setDialogState(() {
                          isProcessing = true;
                          errorMessage = null;
                        });

                        final isValid = await ref.read(authProvider.notifier).checkCurrentPin(enteredPin);
                        if (!isValid) {
                          setDialogState(() {
                            isProcessing = false;
                            errorMessage = 'Incorrect PIN code. Authorization failed.';
                          });
                          return;
                        }

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        await ref.read(authProvider.notifier).resetAll();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dangerRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Verify & Reset',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCurrencyPickerDialog(BuildContext context) {
    final currentCurrency = ref.read(baseCurrencyProvider);
    final currencyList = worldCurrencies.keys.toList()..sort();
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final filteredCurrencies = currencyList
              .where((c) => c.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Select Portfolio Currency', style: TextStyle(fontWeight: FontWeight.w900)),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search currency code (USD, LKR, EUR...)',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        searchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredCurrencies.length,
                      itemBuilder: (context, index) {
                        final curr = filteredCurrencies[index];
                        final symbol = worldCurrencies[curr] ?? '';
                        final isSelected = curr == currentCurrency;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Material(
                            color: isSelected ? AppTheme.emeraldGreen.withValues(alpha: 0.15) : Colors.transparent,
                            shape: isSelected
                                ? RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: AppTheme.emeraldGreen.withValues(alpha: 0.4)),
                                  )
                                : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              title: Text(
                                '$curr ($symbol)',
                                style: TextStyle(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreen, size: 20)
                                  : const Icon(Icons.circle_outlined, size: 20, color: Colors.grey),
                              onTap: () {
                                ref.read(baseCurrencyProvider.notifier).setCurrency(curr);
                                Navigator.pop(ctx);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showNumberFormatPickerDialog(BuildContext context) {
    final currentFormat = ref.read(numberSeparatorFormatProvider);
    final baseCurrency = ref.read(baseCurrencyProvider);
    final symbol = worldCurrencies[baseCurrency] ?? '\$';
    final decimalDigits = ref.read(decimalDigitsProvider);
    final withSpace = ref.read(currencySpacingProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Number & Separator Format', style: TextStyle(fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: NumberSeparatorFormat.values.map((format) {
                final isSelected = format == currentFormat;
                final preview = NumberFormatService.formatAmount(
                  amount: 1234567.89,
                  separatorFormat: format,
                  decimalDigits: decimalDigits,
                  withSpace: withSpace,
                  currencySymbol: symbol,
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      ref.read(numberSeparatorFormatProvider.notifier).setFormat(format);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Format updated to ${format.title}')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.emeraldGreen.withValues(alpha: 0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppTheme.emeraldGreen : Colors.grey.withValues(alpha: 0.2),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  format.title,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                    fontSize: 14,
                                    color: isSelected ? AppTheme.emeraldGreen : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Preview: $preview',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? AppTheme.emeraldGreen : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreen, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDecimalDigitsDialog(BuildContext context) {
    final currentDigits = ref.read(decimalDigitsProvider);
    final currentFormat = ref.read(numberSeparatorFormatProvider);
    final baseCurrency = ref.read(baseCurrencyProvider);
    final symbol = worldCurrencies[baseCurrency] ?? '\$';
    final withSpace = ref.read(currencySpacingProvider);

    final options = [
      {'digits': 0, 'label': '0 Decimals (Whole Integer)'},
      {'digits': 2, 'label': '2 Decimals (Standard .00)'},
      {'digits': 3, 'label': '3 Decimals (High Precision .000)'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Decimal Places Precision', style: TextStyle(fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((opt) {
              final digits = opt['digits'] as int;
              final label = opt['label'] as String;
              final isSelected = digits == currentDigits;
              final preview = NumberFormatService.formatAmount(
                amount: 75432.50,
                separatorFormat: currentFormat,
                decimalDigits: digits,
                withSpace: withSpace,
                currencySymbol: symbol,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    ref.read(decimalDigitsProvider.notifier).setDigits(digits);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Decimal places set to $digits')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.emeraldGreen.withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppTheme.emeraldGreen : Colors.grey.withValues(alpha: 0.2),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                  fontSize: 14,
                                  color: isSelected ? AppTheme.emeraldGreen : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Sample: $preview',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? AppTheme.emeraldGreen : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreen, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
