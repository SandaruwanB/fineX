import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashPage extends StatelessWidget {
    const SplashPage({super.key});

    @override
    Widget build(BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
            body: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [AppTheme.darkBg, const Color(0xFF111827)]
                            : [AppTheme.lightBg, const Color(0xFFE2E8F0)],
                    ),
                ),
                child: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                        colors: [AppTheme.emeraldGreen, AppTheme.neonBlue],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                        BoxShadow(
                                            color: AppTheme.emeraldGreen.withValues(alpha: 0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                        )
                                    ],
                                ),
                                child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Image.asset(
                                        'finex logo.png',
                                        fit: BoxFit.contain,
                                    ),
                                ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                                'fineX',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    foreground: Paint()
                                    ..shader = const LinearGradient(
                                        colors: [AppTheme.emeraldGreen, AppTheme.neonBlue],
                                    ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                                ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                                'Smart Financial Management',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                ),
                            ),
                            const SizedBox(height: 48),
                            const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.emeraldGreen,
                                    ),
                                ),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}
