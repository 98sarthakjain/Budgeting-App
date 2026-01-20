// lib/features/cards/presentation/credit_card_detail_screen.dart
import 'package:flutter/material.dart';

import 'package:budgeting_app/core/design/spacing.dart';
import 'package:budgeting_app/core/design/app_theme.dart';
import 'package:budgeting_app/core/services/app_currency_service.dart';
import 'package:budgeting_app/features/cards/domain/credit_card.dart';
import 'package:budgeting_app/features/transactions/data/transaction_repository.dart';

class CreditCardDetailScreen extends StatelessWidget {
  final CreditCard card;
  final TransactionRepository transactionRepository;

  const CreditCardDetailScreen({
    super.key,
    required this.card,
    required this.transactionRepository,
  });

  @override
  Widget build(BuildContext context) {
    final currency = AppCurrencyService.instance;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Fake tx list for now – later from ledger.
    final todayTx = [
      _TxItem(
        title: 'Starbucks',
        subtitle: 'food and drinks • 33 pts',
        dateLabel: '5 Nov',
        amount: 1685.0,
        isExpense: true,
        icon: Icons.local_cafe,
      ),
      _TxItem(
        title: 'Refund – Amazon',
        subtitle: 'order returned',
        dateLabel: '3 Nov',
        amount: 5728.5,
        isExpense: false,
        icon: Icons.refresh,
      ),
    ];

    final yesterdayTx = [
      _TxItem(
        title: 'Uber',
        subtitle: 'travel',
        dateLabel: '2 Nov',
        amount: 320.0,
        isExpense: true,
        icon: Icons.directions_car,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Credit Cards')),
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
              // Top amount + card settings row
              FutureBuilder<double>(
                future: transactionRepository.computeBalance(
                  accountId: card.id,
                ),
                builder: (context, snapshot) {
                  final amountDue = snapshot.data ?? 0;
                  final amountText = currency.format(amountDue);

                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          amountText,
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: () {
                          // TODO: open card settings screen when available
                        },
                        icon: const Icon(Icons.settings_outlined, size: 18),
                        label: const Text('Card settings'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Centered card
              _CenteredCard(child: _CardHeader(card: card)),
              const SizedBox(height: AppSpacing.lg),

              // Spends summary block
              Text(
                'SPENDS SUMMARY',
                style: textTheme.bodyMedium?.copyWith(
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withAlpha(((0.6) * 255).round()),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SpendSummaryCard(
                currency: currency,
                periodLabel: 'Current statement',
                dateRange:
                    'Billing day ${card.billingDay.toString().padLeft(2, '0')}',
                // For now just show "amount due" as total – later from statement logic.
                totalSpend: null,
              ),
              const SizedBox(height: AppSpacing.lg),

              _SectionTitle('Today'),
              const SizedBox(height: AppSpacing.sm),
              ...todayTx.map((t) => _TxTile(item: t)),
              const SizedBox(height: AppSpacing.lg),

              _SectionTitle('Yesterday'),
              const SizedBox(height: AppSpacing.sm),
              ...yesterdayTx.map((t) => _TxTile(item: t)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenteredCard extends StatelessWidget {
  final Widget child;

  const _CenteredCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width * 0.9;

    return Center(
      child: SizedBox(
        width: cardWidth,
        child: AspectRatio(aspectRatio: 16 / 9, child: child),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final CreditCard card;

  const _CardHeader({required this.card});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final gradients = AppTheme.cardGradients;
    final colors = gradients[card.hashCode.abs() % gradients.length];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: bank + nickname
            Text(
              card.bankName,
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white.withAlpha(((0.9) * 255).round()),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              card.nickname,
              style: textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.credit_card, color: Colors.white, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  card.primaryFace?.last4.isNotEmpty == true
                      ? '•• ${card.primaryFace!.last4}'
                      : '••••',
                  style: textTheme.bodyLarge?.copyWith(color: Colors.white),
                ),
                const Spacer(),
                Text(
                  card.holderName.toUpperCase(),
                  style: textTheme.bodyMedium?.copyWith(
                    letterSpacing: 1.5,
                    color: Colors.white.withAlpha(((0.9) * 255).round()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpendSummaryCard extends StatelessWidget {
  final AppCurrencyService currency;
  final String periodLabel;
  final String dateRange;
  final double? totalSpend; // null -> show placeholder

  const _SpendSummaryCard({
    required this.currency,
    required this.periodLabel,
    required this.dateRange,
    required this.totalSpend,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 6),
            color: Colors.black.withAlpha(((0.04) * 255).round()),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  periodLabel,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'no hidden charges',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                totalSpend == null ? '—' : currency.format(totalSpend!),
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateRange,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withAlpha(((0.7) * 255).round()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Text(title, style: textTheme.titleMedium);
  }
}

class _TxItem {
  final String title;
  final String subtitle;
  final String dateLabel;
  final double amount;
  final bool isExpense;
  final IconData icon;

  const _TxItem({
    required this.title,
    required this.subtitle,
    required this.dateLabel,
    required this.amount,
    required this.isExpense,
    required this.icon,
  });
}

class _TxTile extends StatelessWidget {
  final _TxItem item;

  const _TxTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final currency = AppCurrencyService.instance;

    final amountPrefix = item.isExpense ? '− ' : '+ ';
    final amountColor = item.isExpense ? scheme.error : Colors.green.shade700;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: scheme.surfaceContainerHighest,
        child: Icon(item.icon, size: 20, color: scheme.primary),
      ),
      title: Text(item.title, style: textTheme.bodyLarge),
      subtitle: Text(
        '${item.subtitle}  •  ${item.dateLabel}',
        style: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface.withAlpha(((0.7) * 255).round()),
        ),
      ),
      trailing: Text(
        '$amountPrefix${currency.format(item.amount)}',
        style: textTheme.bodyLarge?.copyWith(
          color: amountColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
