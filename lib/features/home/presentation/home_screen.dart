import 'package:flutter/material.dart';
import 'package:budgeting_app/core/routes.dart';

import 'package:budgeting_app/core/design/spacing.dart';
import 'package:budgeting_app/core/widgets/app_card.dart';
import 'package:budgeting_app/core/widgets/amount_text.dart';
import 'package:budgeting_app/core/services/app_currency_service.dart';

import 'package:budgeting_app/features/transactions/data/transaction_repository.dart';
import 'package:budgeting_app/features/transactions/domain/transaction.dart';
import 'package:budgeting_app/features/savings/data/savings_account_repository.dart';
import 'package:budgeting_app/features/cash/data/cash_account_repository.dart';
import 'package:budgeting_app/features/cards/data/card_repository.dart';

class HomeScreen extends StatefulWidget {
  final TransactionRepository transactionRepository;
  final SavingsAccountRepository savingsRepository;
  final CashAccountRepository cashRepository;
  final CardRepository cardRepository;

  const HomeScreen({
    super.key,
    required this.transactionRepository,
    required this.savingsRepository,
    required this.cashRepository,
    required this.cardRepository,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeSnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _loadSnapshot();
  }

  void _refresh() {
    setState(() {
      _snapshotFuture = _loadSnapshot();
    });
  }

  Future<_HomeSnapshot> _loadSnapshot() async {
    final savings = await widget.savingsRepository.getAllAccounts();
    final cash = await widget.cashRepository.getAllAccounts();
    final cards = await widget.cardRepository.getAllCards();

    double savingsTotal = 0;
    for (final a in savings) {
      savingsTotal += await widget.transactionRepository.computeBalance(
        accountId: a.id,
      );
    }

    double cashTotal = 0;
    for (final a in cash) {
      cashTotal += await widget.transactionRepository.computeBalance(
        accountId: a.id,
      );
    }

    // Credit cards are liabilities: "amount due" = -ledgerBalance.
    double cardDueTotal = 0;
    for (final c in cards) {
      final bal = await widget.transactionRepository.computeBalance(
        accountId: c.id,
      );
      final due = (-bal).clamp(0, double.infinity);
      cardDueTotal += due;
    }

    final allTxns = await widget.transactionRepository.query();
    allTxns.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

    return _HomeSnapshot(
      totalAvailable: savingsTotal + cashTotal - cardDueTotal,
      totalIncome: 0, // TODO: build analytics summaries
      monthIncome: 0,
      totalExpense: 0,
      monthExpense: 0,
      recent: allTxns.take(8).toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = AppCurrencyService.instance;

    return FutureBuilder<_HomeSnapshot>(
      future: _snapshotFuture,
      builder: (context, snap) {
        final snapshot = snap.data;
        final totalBalance = snapshot?.totalAvailable ?? 0.0;

        // For now these remain 0 until we wire analytics to categories.
        final totalIncomeTillDate = snapshot?.totalIncome ?? 0.0;
        final incomeThisMonth = snapshot?.monthIncome ?? 0.0;
        final totalExpenseTillDate = snapshot?.totalExpense ?? 0.0;
        final expenseThisMonth = snapshot?.monthExpense ?? 0.0;

        final categories = <_Category>[
          const _Category(icon: Icons.savings, label: 'Savings'),
          const _Category(icon: Icons.credit_card, label: 'Credit Cards'),
          const _Category(icon: Icons.health_and_safety, label: 'Insurances'),
          const _Category(icon: Icons.trending_up, label: 'Investments'),
          const _Category(icon: Icons.payments, label: 'Cash'),
          const _Category(icon: Icons.account_balance, label: 'Loans'),
        ];

        return Scaffold(
          floatingActionButton: _AddTransactionFab(
            onTransactionAdded: _refresh,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HomeHeader(),
                  const SizedBox(height: AppSpacing.lg),

                  _BalanceCard(totalBalance: totalBalance, currency: currency),
                  const SizedBox(height: AppSpacing.lg),

                  _SummaryRow(
                    currency: currency,
                    totalIncome: totalIncomeTillDate,
                    monthIncome: incomeThisMonth,
                    totalExpense: totalExpenseTillDate,
                    monthExpense: expenseThisMonth,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  const _SectionHeader(title: 'Accounts'),
                  const SizedBox(height: AppSpacing.sm),
                  _CategoriesGrid(
                    categories: categories,
                    onTapCategory: (label) {
                      if (label == 'Credit Cards') {
                        Navigator.of(context).pushNamed(AppRoutes.creditCards);
                      } else if (label == 'Savings') {
                        Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.savingsAccounts);
                      } else if (label == 'Cash') {
                        Navigator.of(context).pushNamed(AppRoutes.cashAccounts);
                      } else if (label == 'Insurances') {
                        Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.insuranceList);
                      } else if (label == 'Investments') {
                        Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.investmentsDashboard);
                      } else if (label == 'Loans') {
                        Navigator.of(context).pushNamed(AppRoutes.loans);
                      }
                    },
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  const _SectionHeader(title: 'Transactions'),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    child: Column(
                      children: [
                        if (snap.connectionState == ConnectionState.waiting)
                          const Padding(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if ((snapshot?.recent ?? const <Transaction>[])
                            .isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: Text('No transactions yet'),
                          )
                        else
                          for (final t in snapshot!.recent)
                            _RecentTileFromTxn(txn: t, currency: currency),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeSnapshot {
  final double totalAvailable;
  final double totalIncome;
  final double monthIncome;
  final double totalExpense;
  final double monthExpense;
  final List<Transaction> recent;

  const _HomeSnapshot({
    required this.totalAvailable,
    required this.totalIncome,
    required this.monthIncome,
    required this.totalExpense,
    required this.monthExpense,
    required this.recent,
  });
}

class _RecentTileFromTxn extends StatelessWidget {
  final Transaction txn;
  final AppCurrencyService currency;

  const _RecentTileFromTxn({required this.txn, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isExpense = txn.type == TransactionType.expense;
    final title = (txn.description?.trim().isNotEmpty ?? false)
        ? txn.description!.trim()
        : (isExpense ? 'Expense' : 'Income');
    final subtitle =
        'Account ${txn.accountId} • ${_formatDate(txn.bookingDate)}';

    return _RecentTile(
      title: title,
      category: txn.categoryId ?? 'Uncategorized',
      paidVia: subtitle,
      amount: txn.amount,
      isExpense: isExpense,
      icon: isExpense ? Icons.arrow_upward : Icons.arrow_downward,
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final d = date.day.toString().padLeft(2, '0');
  final m = months[date.month - 1];
  return '$d $m';
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('Welcome Sarthak', style: textTheme.titleLarge)],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {
                // TODO: notifications screen
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.dataTools);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double totalBalance;
  final AppCurrencyService currency;

  const _BalanceCard({required this.totalBalance, required this.currency});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available balance',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onPrimary.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currency.format(totalBalance),
            style: textTheme.headlineMedium?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'FY 2025–26',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onPrimary.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final AppCurrencyService currency;
  final double totalIncome;
  final double monthIncome;
  final double totalExpense;
  final double monthExpense;

  const _SummaryRow({
    required this.currency,
    required this.totalIncome,
    required this.monthIncome,
    required this.totalExpense,
    required this.monthExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Total Income',
            totalAmount: totalIncome,
            monthAmount: monthIncome,
            currency: currency,
            isIncome: true,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SummaryCard(
            label: 'Total Expense',
            totalAmount: totalExpense,
            monthAmount: monthExpense,
            currency: currency,
            isIncome: false,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double totalAmount;
  final double monthAmount;
  final AppCurrencyService currency;
  final bool isIncome;

  const _SummaryCard({
    required this.label,
    required this.totalAmount,
    required this.monthAmount,
    required this.currency,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final Color bg;
    final Color borderColor;
    final Color fg;

    if (isIncome) {
      bg = scheme.secondaryContainer;
      borderColor = scheme.secondary;
      fg = scheme.onSecondaryContainer;
    } else {
      bg = scheme.errorContainer.withOpacity(0.2);
      borderColor = scheme.error.withOpacity(0.6);
      fg = scheme.onErrorContainer.withOpacity(0.9);
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodyMedium?.copyWith(color: fg)),
          const SizedBox(height: 8),
          Text(
            currency.format(totalAmount),
            style: textTheme.bodyLarge?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Till date',
            style: textTheme.bodyMedium?.copyWith(color: fg.withOpacity(0.85)),
          ),
          const SizedBox(height: 4),
          Text(
            '${currency.format(monthAmount)} • April 2025',
            style: textTheme.bodyMedium?.copyWith(color: fg.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: textTheme.titleMedium),
        if (actionLabel != null &&
            actionLabel!.isNotEmpty &&
            onActionTap != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionLabel!,
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _Category {
  final IconData icon;
  final String label;
  const _Category({required this.icon, required this.label});
}

class _CategoriesGrid extends StatelessWidget {
  final List<_Category> categories;
  final void Function(String label)? onTapCategory;

  const _CategoriesGrid({required this.categories, this.onTapCategory});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GridView.builder(
      itemCount: categories.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.lg,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final c = categories[index];
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onTapCategory?.call(c.label),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(c.icon, size: 24, color: scheme.primary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                c.label,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecentTile extends StatelessWidget {
  final String title;
  final String category;
  final String paidVia;
  final double amount;
  final bool isExpense;
  final IconData icon;

  const _RecentTile({
    required this.title,
    required this.category,
    required this.paidVia,
    required this.amount,
    required this.isExpense,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: scheme.surfaceVariant,
        child: Icon(icon, size: 20, color: scheme.primary),
      ),
      title: Text(title, style: textTheme.bodyLarge),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withOpacity(0.75),
            ),
          ),
          Text(
            'Paid via $paidVia',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
      trailing: AmountText(amountInInr: amount, isExpense: isExpense),
    );
  }
}

class _AddTransactionFab extends StatelessWidget {
  final VoidCallback onTransactionAdded;

  const _AddTransactionFab({required this.onTransactionAdded});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        final parentContext = context;

        showModalBottomSheet<void>(
          context: parentContext,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (sheetContext) {
            final textTheme = Theme.of(sheetContext).textTheme;

            Future<void> goToAdd() async {
              Navigator.of(sheetContext).pop(); // close sheet first
              final changed = await Navigator.of(
                parentContext,
              ).pushNamed(AppRoutes.addTransaction);
              if (changed == true) onTransactionAdded();
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg + 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add transaction', style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  ListTile(
                    leading: const Icon(Icons.arrow_downward),
                    title: const Text('Income'),
                    onTap: goToAdd,
                  ),
                  ListTile(
                    leading: const Icon(Icons.arrow_upward),
                    title: const Text('Expense'),
                    onTap: goToAdd,
                  ),
                ],
              ),
            );
          },
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('Add transaction'),
    );
  }
}
