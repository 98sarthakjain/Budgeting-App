import 'package:flutter/material.dart';
import 'package:budgeting_app/core/routes.dart';

import 'package:budgeting_app/core/design/spacing.dart';
import 'package:budgeting_app/core/widgets/app_card.dart';
import 'package:budgeting_app/core/widgets/amount_text.dart';
import 'package:budgeting_app/core/services/app_currency_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = AppCurrencyService.instance;

    // TODO: Replace with real repository data.
    final totalBalance = 125000.0;

    // For now these are placeholders; later we can wire them to real data.
    final totalIncomeTillDate = 1800.0;
    final incomeThisMonth = 600.0;
    final totalExpenseTillDate = 1200.0;
    final expenseThisMonth = 400.0;

    final categories = <_Category>[
      const _Category(icon: Icons.savings, label: 'Savings'),
      const _Category(icon: Icons.credit_card, label: 'Credit Cards'),
      const _Category(icon: Icons.health_and_safety, label: 'Insurances'),
      const _Category(icon: Icons.trending_up, label: 'Investments'),
      const _Category(icon: Icons.payments, label: 'Cash'),
      const _Category(icon: Icons.account_balance, label: 'Loans'),
    ];

    final recents = <Map<String, Object>>[
      {
        'title': 'Water Bill',
        'category': 'Utilities',
        'paidVia': 'Amazon ICICI',
        'amount': 280.0,
        'isExpense': true,
        'icon': Icons.water_drop,
      },
      {
        'title': 'Electric Bill',
        'category': 'Utilities',
        'paidVia': 'Amazon ICICI',
        'amount': 480.0,
        'isExpense': true,
        'icon': Icons.bolt,
      },
      {
        'title': 'Income: Salary Oct',
        'category': 'Salary',
        'paidVia': 'Savings Account',
        'amount': 1200.0,
        'isExpense': false,
        'icon': Icons.account_balance_wallet,
      },
    ];

    return Scaffold(
      floatingActionButton: const _AddTransactionFab(),
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
                    Navigator.of(context).pushNamed(AppRoutes.savingsAccounts);
                  } else if (label == 'Cash') {
                    Navigator.of(context).pushNamed(AppRoutes.cashAccounts);
                  } else if (label == 'Insurances') {
                    Navigator.of(context).pushNamed(AppRoutes.insuranceList);
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
                    for (final item in recents)
                      _RecentTile(
                        title: item['title'] as String,
                        category: item['category'] as String,
                        paidVia: item['paidVia'] as String,
                        amount: item['amount'] as double,
                        isExpense: item['isExpense'] as bool,
                        icon: item['icon'] as IconData,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
          children: [
            Text(
              'Welcome Sarthak',
              // Slightly smaller than headline so it doesn’t dominate.
              style: textTheme.titleLarge,
            ),
          ],
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
                // TODO: settings screen
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
        color: scheme.primary, // solid blue like the mock
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available balance',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onPrimary.withAlpha(((0.9) * 255).round()),
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
              color: scheme.onPrimary.withAlpha(((0.85) * 255).round()),
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
      // Softer "warning" tone instead of harsh red
      bg = scheme.errorContainer.withAlpha(((0.2) * 255).round());
      borderColor = scheme.error.withAlpha(((0.6) * 255).round());
      fg = scheme.onErrorContainer.withAlpha(((0.9) * 255).round());
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withAlpha(((0.5) * 255).round()), width: 1),
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
            style: textTheme.bodyMedium?.copyWith(color: fg.withAlpha(((0.85) * 255).round())),
          ),
          const SizedBox(height: 4),
          Text(
            '${currency.format(monthAmount)} • April 2025',
            style: textTheme.bodyMedium?.copyWith(color: fg.withAlpha(((0.8) * 255).round())),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: textTheme.titleMedium),
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
                  color: scheme.surfaceContainerHighest,
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
        backgroundColor: scheme.surfaceContainerHighest,
        child: Icon(icon, size: 20, color: scheme.primary),
      ),
      title: Text(title, style: textTheme.bodyLarge),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withAlpha(((0.75) * 255).round()),
            ),
          ),
          Text(
            'Paid via $paidVia',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withAlpha(((0.6) * 255).round()),
            ),
          ),
        ],
      ),
      trailing: AmountText(amountInInr: amount, isExpense: isExpense),
    );
  }
}

class _AddTransactionFab extends StatelessWidget {
  const _AddTransactionFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) {
            final textTheme = Theme.of(context).textTheme;
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
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: pass "income" type once logic supports it.
                      Navigator.of(context).pushNamed(AppRoutes.addTransaction);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.arrow_upward),
                    title: const Text('Expense'),
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: pass "expense" type once logic supports it.
                      Navigator.of(context).pushNamed(AppRoutes.addTransaction);
                    },
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
