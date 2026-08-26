import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      title: 'Take Control of\nYour Wealth',
      description:
          'Track all your assets, bank accounts, and investments in one secure dashboard. Effortless oversight.',
      icon: Icons.account_balance_wallet_rounded,
      gradient: [const Color(0xFF10B981), const Color(0xFF059669)],
    ),
    OnboardingSlideData(
      title: 'Set Budgets,\nSave Smarter',
      description:
          'Create customizable budgets that adapt to your monthly needs. Get notified before you overspend.',
      icon: Icons.pie_chart_rounded,
      gradient: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
    ),
    OnboardingSlideData(
      title: 'AI-Powered\nWealth Insights',
      description:
          'Unlock insights into your spending patterns. Securely analyze trends to grow your net worth over time.',
      icon: Icons.auto_awesome_rounded,
      gradient: [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    ref.read(authProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _slides[_currentPage].gradient[0].withValues(alpha: 0.08),
                    blurRadius: 100,
                    spreadRadius: 100,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _slides[_currentPage].gradient[1].withValues(alpha: 0.08),
                    blurRadius: 80,
                    spreadRadius: 80,
                  ),
                ],
              ),
            ),
          ),

          // Main Onboarding Flow
          SafeArea(
            child: Column(
              children: [
                // Top Header (Logo + Skip)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Mini Brand logo
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _slides[_currentPage].gradient,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'fineX',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                          ),
                        ],
                      ),
                      // Skip Button
                      if (_currentPage < _slides.length - 1)
                        TextButton(
                          onPressed: _completeOnboarding,
                          child: const Text('Skip'),
                        )
                      else
                        const SizedBox(height: 48), // Spacer to maintain layout
                    ],
                  ),
                ),

                // Slides PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Interactive/Animated Graphic Container
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: slide.gradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: [
                                  BoxShadow(
                                    color: slide.gradient[0].withValues(alpha: 0.3),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Icon(
                                slide.icon,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 60),
                            // Slide Title
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontSize: 32,
                                    height: 1.2,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            // Slide Description
                            Text(
                              slide.description,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontSize: 15, height: 1.5),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Navigation controls (Indicators + Button)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      // Dots Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _slides.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentPage == index
                                  ? _slides[_currentPage].gradient[0]
                                  : (isDark ? Colors.white24 : Colors.black12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Continue Button
                      ElevatedButton(
                        onPressed: _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _slides[_currentPage].gradient[0],
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _currentPage == _slides.length - 1
                              ? 'Get Started'
                              : 'Continue',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingSlideData {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;

  OnboardingSlideData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}
