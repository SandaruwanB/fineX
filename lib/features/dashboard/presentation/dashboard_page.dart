import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';

import '../../../core/widgets/main_drawer.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _isMenuOpen = false;
  Offset _fabPosition = const Offset(-1, -1);

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final size = MediaQuery.of(context).size;

    if (_fabPosition == const Offset(-1, -1)) {
      _fabPosition = Offset(size.width - 72, size.height - 200);
    }

    return Scaffold(
      drawer: const MainDrawer(activeRoute: '/dashboard'),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('fineX'),
      ),
      body: Stack(
        children: [
          // Main Scroll View
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header (User Info)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Alex Morgan',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 2. Net Worth Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                              : [Colors.white, const Color(0xFFF1F5F9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TOTAL NET WORTH',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.emeraldGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '+5.2%',
                                  style: TextStyle(
                                    color: AppTheme.emeraldGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$142,850.40',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildBalanceIndicator(
                                  title: 'Monthly Income',
                                  amount: '\$8,450.00',
                                  icon: Icons.arrow_upward_rounded,
                                  iconColor: AppTheme.emeraldGreen,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                              ),
                              Expanded(
                                child: _buildBalanceIndicator(
                                  title: 'Monthly Expenses',
                                  amount: '\$3,120.50',
                                  icon: Icons.arrow_downward_rounded,
                                  iconColor: AppTheme.dangerRed,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 4. Wealth Growth Chart Title
                    Text(
                      'Wealth Growth',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Interactive Line Chart
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: 7,
                          minY: 0,
                          maxY: 6,
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 3),
                                FlSpot(1, 2.5),
                                FlSpot(2, 4),
                                FlSpot(3, 3.5),
                                FlSpot(4, 5),
                                FlSpot(5, 4.5),
                                FlSpot(6, 5.5),
                              ],
                              isCurved: true,
                              color: AppTheme.emeraldGreen,
                              barWidth: 4,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.emeraldGreen.withValues(alpha: 0.3),
                                    AppTheme.emeraldGreen.withValues(alpha: 0.0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 6. Recent Transactions List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Transactions',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(onPressed: () {}, child: const Text('See All')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTransactionRow(
                      context,
                      title: 'Grocery Store',
                      subtitle: 'Food & Dining',
                      amount: '-\$84.50',
                      date: 'Today, 2:45 PM',
                      icon: Icons.shopping_basket_rounded,
                      iconBg: Colors.orange.withValues(alpha: 0.15),
                      iconColor: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildTransactionRow(
                      context,
                      title: 'Monthly Salary',
                      subtitle: 'Corporate Deposit',
                      amount: '+\$4,800.00',
                      date: 'Yesterday, 9:00 AM',
                      icon: Icons.work_rounded,
                      iconBg: Colors.green.withValues(alpha: 0.15),
                      iconColor: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildTransactionRow(
                      context,
                      title: 'Netflix Subscription',
                      subtitle: 'Entertainment',
                      amount: '-\$15.49',
                      date: 'Aug 14, 2026',
                      icon: Icons.tv_rounded,
                      iconBg: Colors.red.withValues(alpha: 0.15),
                      iconColor: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Translucent Backdrop Overlay when FAB is open
          if (_isMenuOpen)
            GestureDetector(
              onTap: () => setState(() => _isMenuOpen = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                color: Colors.black.withValues(alpha: 0.5),
                width: double.infinity,
                height: double.infinity,
              ),
            ),

          // Draggable/Movable FAB assembly
          ..._buildDraggableFabMenu(context, isDark, size),
        ],
      ),
    );
  }

  void _updateFabPosition(Offset delta, Size screenSize) {
    setState(() {
      double newX = _fabPosition.dx + delta.dx;
      double newY = _fabPosition.dy + delta.dy;

      // Define safety margins
      const double padding = 16.0;
      final double minX = padding;
      final double maxX = screenSize.width - 56.0 - padding;
      
      final double minY = kToolbarHeight + padding;
      final double maxY = screenSize.height - 80.0 - padding;

      _fabPosition = Offset(
        newX.clamp(minX, maxX),
        newY.clamp(minY, maxY),
      );
    });
  }

  List<Widget> _buildDraggableFabMenu(BuildContext context, bool isDark, Size screenSize) {
    final showUpward = _fabPosition.dy > screenSize.height / 2;

    final items = [
      _FabItem(
        icon: Icons.send_rounded,
        label: 'Record Expense',
        color: AppTheme.dangerRed,
        onTap: () {
          setState(() => _isMenuOpen = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Send Money selected')),
          );
        },
      ),
      _FabItem(
        icon: Icons.call_received_rounded,
        label: 'Receive Money',
        color: AppTheme.emeraldGreen,
        onTap: () {
          setState(() => _isMenuOpen = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receive Money selected')),
          );
        },
      ),
      _FabItem(
        icon: Icons.swap_horiz_rounded,
        label: 'Account Transfer',
        color: AppTheme.neonBlue,
        onTap: () {
          setState(() => _isMenuOpen = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account Transfer selected')),
          );
        },
      ),
    ];

    List<Widget> stackChildren = [];

    // Add child options if menu is open
    if (_isMenuOpen) {
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final double topOffset = showUpward
            ? _fabPosition.dy - 52 - (i * 52)
            : _fabPosition.dy + 68 + (i * 52);

        stackChildren.add(
          Positioned(
            right: screenSize.width - _fabPosition.dx - 56,
            top: topOffset,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.small(
                  heroTag: 'fab-${item.label}',
                  onPressed: item.onTap,
                  backgroundColor: item.color,
                  foregroundColor: Colors.white,
                  child: Icon(item.icon, size: 20),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      }
    }

    // Add main FAB
    stackChildren.add(
      Positioned(
        left: _fabPosition.dx,
        top: _fabPosition.dy,
        child: GestureDetector(
          onPanUpdate: (details) {
            _updateFabPosition(details.delta, screenSize);
          },
          onTap: () {
            setState(() {
              _isMenuOpen = !_isMenuOpen;
            });
          },
          child: FloatingActionButton(
            heroTag: 'main-fab',
            onPressed: null,
            backgroundColor: AppTheme.emeraldGreen,
            foregroundColor: Colors.black,
            child: AnimatedRotation(
              turns: _isMenuOpen ? 0.125 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(Icons.add_rounded, size: 28),
            ),
          ),
        ),
      ),
    );

    return stackChildren;
  }

  Widget _buildBalanceIndicator({
    required String title,
    required String amount,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTransactionRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String amount,
    required String date,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = amount.startsWith('+');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161C2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isIncome
                      ? AppTheme.emeraldGreen
                      : (isDark ? Colors.white : Colors.black),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FabItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _FabItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
