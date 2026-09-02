import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/currencies.dart';
import '../../../core/services/preference_service.dart';
import '../../../core/widgets/main_drawer.dart';
import '../../../core/widgets/currency_display.dart';
import '../accounts_provider.dart';
import '../../transactions/transactions_provider.dart';

class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _showAddAccountBottomSheet() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedType = 'checking';
    Color selectedColor = AppTheme.wealthGreen;

    final colors = [
      AppTheme.wealthGreen,
      AppTheme.neonBlue,
      AppTheme.goldAccent,
      const Color(0xFF8B5CF6), // Royal Purple
      const Color(0xFFF43F5E), // Crimson
      const Color(0xFF1E293B), // Obsidian
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101726) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Issue Digital Account / Card',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Account / Card Name',
                        hintText: 'e.g. Executive Checking',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: balanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Initial Balance',
                        hintText: 'e.g. 5000.00',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Account Tier',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'checking', child: Text('Checking / Current Account')),
                        DropdownMenuItem(value: 'savings', child: Text('High-Yield Savings Vault')),
                        DropdownMenuItem(value: 'credit', child: Text('Obsidian Credit Card')),
                        DropdownMenuItem(value: 'cash', child: Text('Physical Cash Wallet')),
                        DropdownMenuItem(value: 'loan', child: Text('Commercial / Term Loan')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Card Theme Hue',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: colors.map((color) {
                        final isSelected = selectedColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final name = nameController.text.trim();
                              final balance = double.tryParse(balanceController.text.trim()) ?? 0.0;
                              if (name.isNotEmpty) {
                                ref.read(accountsProvider.notifier).addAccount(
                                      name,
                                      balance,
                                      selectedType,
                                      selectedColor,
                                    );
                                Navigator.pop(ctx);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.wealthGreen,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Issue Account'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTransferModal(BuildContext context, List<Account> accounts) {
    if (accounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need at least 2 accounts to execute a transfer.')),
      );
      return;
    }

    String sourceId = accounts[0].id;
    String targetId = accounts[1].id;
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF101726) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Instant Account Transfer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),

                // Source Account
                DropdownButtonFormField<String>(
                  initialValue: sourceId,
                  decoration: const InputDecoration(labelText: 'From Source Account'),
                  items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => sourceId = val);
                  },
                ),
                const SizedBox(height: 16),

                // Target Account
                DropdownButtonFormField<String>(
                  initialValue: targetId,
                  decoration: const InputDecoration(labelText: 'To Destination Account'),
                  items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => targetId = val);
                  },
                ),
                const SizedBox(height: 16),

                // Transfer Amount
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Transfer Amount', hintText: '0.00'),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                    if (amount <= 0 || sourceId == targetId) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select different accounts and a valid amount.')),
                      );
                      return;
                    }

                    HapticFeedback.heavyImpact();

                    await ref.read(transactionsProvider.notifier).addTransaction(
                      amount: amount,
                      timestamp: DateTime.now(),
                      accountId: sourceId,
                      categoryId: null,
                      description: 'Account Transfer',
                      flowDirection: 'TRANSFER',
                      transactionType: 'TRANSFER',
                      baseCurrencyAmount: amount,
                      exchangeRate: 1.0,
                      transferTargetAccountId: targetId,
                    );

                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transfer executed successfully!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.wealthGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Execute Instant Transfer', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalBalance = accounts.fold<double>(
      0.0,
      (sum, acc) => acc.type == 'credit' ? sum - acc.balance.abs() : sum + acc.balance,
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: const MainDrawer(activeRoute: '/accounts'),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Center(
              child: InkWell(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161C2A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Icon(
                    Icons.menu_rounded,
                    size: 20,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: const Text('Accounts & Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Account Transfer',
            onPressed: () => _showTransferModal(context, accounts),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Top Balance & Action Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CONSOLIDATED VALUATION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      CurrencyDisplay(
                        amount: totalBalance,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddAccountBottomSheet,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.wealthGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: const Text(
                      'Link Card',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Card Deck List
              Expanded(
                child: accounts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.credit_card_off_rounded, size: 44, color: Colors.grey.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            const Text('No Accounts Linked', style: TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            const Text('Tap "Link Card" above to add your first account.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: accounts.length,
                        itemBuilder: (context, index) {
                          final account = accounts[index];
                          return _buildPhysicalCard(context, account, isDark);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Physical Bank Card UI ---
  Widget _buildPhysicalCard(BuildContext context, Account account, bool isDark) {
    final isCredit = account.type == 'credit';
    final baseCurrency = ref.watch(baseCurrencyProvider);
    final symbol = worldCurrencies[baseCurrency] ?? '\$';

    // Tailored gradient textures based on account type
    LinearGradient cardGradient;
    if (account.type == 'checking') {
      cardGradient = AppTheme.wealthEmeraldGradient;
    } else if (account.type == 'savings') {
      cardGradient = const LinearGradient(
        colors: [Color(0xFF334155), Color(0xFF1E293B), Color(0xFF0F172A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (account.type == 'credit') {
      cardGradient = const LinearGradient(
        colors: [Color(0xFF1E1E24), Color(0xFF121217), Color(0xFF08080A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      cardGradient = LinearGradient(
        colors: [account.color, account.color.withValues(alpha: 0.7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Holographic Metallic Sheen
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Card Title & Contactless Wave + Delete Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            account.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.contactless_rounded, size: 18, color: Colors.white.withValues(alpha: 0.7)),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              account.type.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              ref.read(accountsProvider.notifier).deleteAccount(account.id);
                            },
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white.withValues(alpha: 0.6),
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Middle Row: Gold EMV Chip Graphic
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFD4AF37), Color(0xFFB8860B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFFF8DC), width: 0.8),
                        ),
                        child: Center(
                          child: Container(
                            width: 24,
                            height: 18,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black26, width: 0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        '•••• •••• •••• ${account.id.substring(account.id.length > 4 ? account.id.length - 4 : 0)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),

                  // Bottom Row: Balance & Cardholder Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCredit ? 'CURRENT OUTSTANDING' : 'AVAILABLE BALANCE',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$symbol${account.balance.abs().toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'SANDARUWAN B.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
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
    );
  }
}
