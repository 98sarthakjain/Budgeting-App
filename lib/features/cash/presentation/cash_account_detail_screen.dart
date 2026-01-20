import 'package:flutter/material.dart';

import 'package:budgeting_app/core/design/spacing.dart';
import 'package:budgeting_app/core/widgets/app_card.dart';
import 'package:budgeting_app/core/services/app_currency_service.dart';
import 'package:budgeting_app/features/cash/domain/cash_account.dart';
import 'package:budgeting_app/features/transactions/data/transaction_repository.dart';
import 'package:budgeting_app/features/transactions/domain/transaction.dart';

class CashAccountDetailScreen extends StatelessWidget {
  final CashAccount account;
  final TransactionRepository transactionRepository;

  const CashAccountDetailScreen({
    super.key,
    required this.account,
    required this.transactionRepository,
  });

  double _computeBalance(List<Transaction> txns) {
    double balance = 0;

    for (final t in txns) {
      switch (t.type) {
        case TransactionType.income:
        case TransactionType.transferIn:
        case TransactionType.openingBalance:
          balance += t.amount;
          break;

        case TransactionType.expense:
        case TransactionType.transferOut:
          balance -= t.amount;
          break;

        case TransactionType.adjustment:
          if (t.adjustmentDirection == AdjustmentDirection.increase) {
            balance += t.amount;
          } else if (t.adjustmentDirection == AdjustmentDirection.decrease) {
            balance -= t.amount;
          }
          break;
      }
    }

    return balance;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currency = AppCurrencyService.instance;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name, style: textTheme.titleLarge),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<List<Transaction>>(
          stream: transactionRepository.watchByAccount(accountId: account.id),
          initialData: const [],
          builder: (context, snapshot) {
            final txns = snapshot.data ?? const <Transaction>[];
            final ledgerBalance = _computeBalance(txns);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top balance (from ledger)
                  Text(
                    currency.format(ledgerBalance),
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Ledger balance',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withAlpha(((0.7) * 255).round()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Summary card
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Account details', style: textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.md),

                          _DetailRow(label: 'Name', value: account.name),
                          _DetailRow(
                            label: 'Ledger balance',
                            value: currency.format(ledgerBalance),
                          ),
                          _DetailRow(label: 'Account ID', value: account.id),
                          if (account.isClosed && account.closedAt != null)
                            _DetailRow(
                              label: 'Status',
                              value:
                                  'Closed on ${account.closedAt!.toLocal().toString().split(' ').first}',
                            )
                          else if (account.isClosed)
                            const _DetailRow(label: 'Status', value: 'Closed'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Transactions section
                  Text('Transactions', style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),

                  if (txns.isEmpty)
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          'No transactions yet.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withAlpha(((0.7) * 255).round()),
                          ),
                        ),
                      ),
                    )
                  else
                    AppCard(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: txns.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, thickness: 0.5),
                        itemBuilder: (context, index) {
                          final t = txns[index];
                          return _TransactionTile(
                            txn: t,
                            currency: currency,
                            textTheme: textTheme,
                            scheme: scheme,
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withAlpha(((0.7) * 255).round()),
              ),
            ),
          ),
          Text(value, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction txn;
  final AppCurrencyService currency;
  final TextTheme textTheme;
  final ColorScheme scheme;

  const _TransactionTile({
    required this.txn,
    required this.currency,
    required this.textTheme,
    required this.scheme,
  });

  bool get _isCredit {
    switch (txn.type) {
      case TransactionType.income:
      case TransactionType.transferIn:
      case TransactionType.openingBalance:
        return true;
      case TransactionType.expense:
      case TransactionType.transferOut:
        return false;
      case TransactionType.adjustment:
        return txn.adjustmentDirection == AdjustmentDirection.increase;
    }
  }

  String get _typeLabel {
    switch (txn.type) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transferIn:
        return 'Transfer in';
      case TransactionType.transferOut:
        return 'Transfer out';
      case TransactionType.openingBalance:
        return 'Opening balance';
      case TransactionType.adjustment:
        return 'Adjustment';
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountText = currency.format(txn.amount);
    final sign = _isCredit ? '+' : '-';

    final amountStyle = textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: _isCredit ? scheme.tertiary : scheme.error,
    );

    final dateStr = txn.bookingDate.toLocal().toString().split(' ').first;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Leading dot / icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              size: 18,
              color: _isCredit ? scheme.tertiary : scheme.error,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Main text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.description ?? _typeLabel,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateStr · $_typeLabel',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withAlpha(((0.7) * 255).round()),
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Text('$sign$amountText', style: amountStyle),
        ],
      ),
    );
  }
}
