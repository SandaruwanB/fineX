import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/main_drawer.dart';
import '../../../core/widgets/currency_display.dart';
import '../../../core/widgets/fade_slide_transition.dart';
import '../../../core/widgets/drawer_blur_wrapper.dart';
import '../accounts_provider.dart';
import '../../transactions/transactions_provider.dart';

class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;

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
      const Color(0xFF0EA5E9), // Sky Blue
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
                      'Link Account / Card',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Account / Bank Name',
                        hintText: 'e.g. Commercial Bank, Cash Wallet',
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
                      'Account Classification',
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
                        DropdownMenuItem(value: 'savings', child: Text('Savings Account / Vault')),
                        DropdownMenuItem(value: 'credit', child: Text('Credit Card (Liability)')),
                        DropdownMenuItem(value: 'cash', child: Text('Physical Cash Wallet')),
                        DropdownMenuItem(value: 'loan', child: Text('Personal / Term Loan')),
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
                      'Accent Hue',
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
                            child: const Text('Save Account'),
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

  void _showEditAccountBottomSheet(Account account) {
    final nameController = TextEditingController(text: account.name);
    String selectedType = account.type;
    Color selectedColor = account.color;

    final colors = [
      AppTheme.wealthGreen,
      AppTheme.neonBlue,
      AppTheme.goldAccent,
      const Color(0xFF8B5CF6), // Royal Purple
      const Color(0xFFF43F5E), // Crimson
      const Color(0xFF0EA5E9), // Sky Blue
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final isCredit = selectedType == 'credit';

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Account / Card',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: account.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            account.type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: account.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Account Name Field
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Account / Bank Name',
                        hintText: 'e.g. Commercial Bank, Cash Wallet',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Read-only Balance Banner (Preserves Ledger Consistency)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isCredit ? AppTheme.dangerRed : AppTheme.emeraldGreen).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_rounded,
                              size: 16,
                              color: isCredit ? AppTheme.dangerRed : AppTheme.emeraldGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Flexible(
                                      child: Text(
                                        'Current Balance (Locked)',
                                        style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w700),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    CurrencyDisplay(
                                      amount: isCredit ? -account.balance.abs() : account.balance,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: isCredit ? AppTheme.dangerRed : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Balance is updated automatically via ledger transactions.',
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    const Text(
                      'Account Classification',
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
                        DropdownMenuItem(value: 'savings', child: Text('Savings Account / Vault')),
                        DropdownMenuItem(value: 'credit', child: Text('Credit Card (Liability)')),
                        DropdownMenuItem(value: 'cash', child: Text('Physical Cash Wallet')),
                        DropdownMenuItem(value: 'loan', child: Text('Personal / Term Loan')),
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
                      'Accent Hue',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: colors.map((color) {
                        final isSelected = selectedColor.toARGB32() == color.toARGB32();
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
                              if (name.isNotEmpty) {
                                ref.read(accountsProvider.notifier).updateAccount(
                                      id: account.id,
                                      name: name,
                                      type: selectedType,
                                      color: selectedColor,
                                    );
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Account updated successfully.')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.wealthGreen,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Save Changes'),
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
                  child: const Text('Execute Transfer', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, Account account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Unlink Account', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          'Are you sure you want to remove "${account.name}"? Past transactions associated with this account will remain in history.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(accountsProvider.notifier).deleteAccount(account.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${account.name} unlinked successfully.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Remove Account'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double liquidTotal = 0.0;
    double liabilityTotal = 0.0;

    for (var acc in accounts) {
      if (acc.type == 'credit' || acc.type == 'loan') {
        liabilityTotal += acc.balance.abs();
      } else {
        liquidTotal += acc.balance;
      }
    }

    final totalBalance = liquidTotal - liabilityTotal;

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
        drawer: const MainDrawer(activeRoute: '/accounts'),
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
          title: const Text('Accounts & Cards'),
          actions: [
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: 'Transfer',
              onPressed: () => _showTransferModal(context, accounts),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: DrawerBlurWrapper(
          isDrawerOpen: _isDrawerOpen,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Compact Consolidated Valuation & Quick Action Header
                  FadeSlideTransition(
                    delay: Duration.zero,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131D2E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'NET VALUATION',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  CurrencyDisplay(
                                    amount: totalBalance,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: _showAddAccountBottomSheet,
                                icon: const Icon(Icons.add_rounded, size: 15),
                                label: const Text('Add Account', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.wealthGreen,
                                  foregroundColor: Colors.white,
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.wealthGreen.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Liquid: ', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                                    CurrencyDisplay(
                                      amount: liquidTotal,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.emeraldGreen),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.dangerRed.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Debt: ', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                                    CurrencyDisplay(
                                      amount: liabilityTotal,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.dangerRed),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LINKED ACCOUNTS (${accounts.length})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: Colors.grey,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showTransferModal(context, accounts),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                        label: const Text('Transfer Funds', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.emeraldGreen,
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Compact Account List
                  Expanded(
                    child: FadeSlideTransition(
                      delay: const Duration(milliseconds: 70),
                      child: accounts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.credit_card_off_rounded, size: 40, color: Colors.grey.withValues(alpha: 0.4)),
                                  const SizedBox(height: 10),
                                  const Text('No Accounts Linked', style: TextStyle(fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  const Text('Tap "Add Account" above to link your first card or wallet.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: accounts.length,
                              itemBuilder: (context, index) {
                                final account = accounts[index];
                                return _buildCompactAccountTile(context, account, isDark);
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Compact & High-Density Account Tile ---
  Widget _buildCompactAccountTile(BuildContext context, Account account, bool isDark) {
    final isCredit = account.type == 'credit' || account.type == 'loan';
    final last4 = account.id.length > 4 ? account.id.substring(account.id.length - 4) : account.id;

    IconData icon;
    String typeLabel;

    switch (account.type) {
      case 'savings':
        icon = Icons.savings_rounded;
        typeLabel = 'Savings Vault';
        break;
      case 'credit':
        icon = Icons.credit_card_rounded;
        typeLabel = 'Credit Card';
        break;
      case 'cash':
        icon = Icons.payments_rounded;
        typeLabel = 'Physical Cash';
        break;
      case 'loan':
        icon = Icons.receipt_long_rounded;
        typeLabel = 'Loan Liability';
        break;
      case 'checking':
      default:
        icon = Icons.account_balance_rounded;
        typeLabel = 'Checking Account';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showEditAccountBottomSheet(account),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon Container with Account Color
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: account.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: account.color.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: account.color, size: 22),
                ),
                const SizedBox(width: 14),

                // Account Details (Name & Type)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                typeLabel,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (last4.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '•••• $last4',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Balance
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CurrencyDisplay(
                      amount: isCredit ? -account.balance.abs() : account.balance,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isCredit
                            ? AppTheme.dangerRed
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCredit ? 'Outstanding' : 'Available',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isCredit ? AppTheme.dangerRed.withValues(alpha: 0.8) : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),

                // Options Menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey[400]),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showEditAccountBottomSheet(account);
                    } else if (val == 'delete') {
                      _confirmDeleteAccount(context, account);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Edit Account', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.dangerRed),
                          SizedBox(width: 8),
                          Text('Unlink Account', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.dangerRed)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
