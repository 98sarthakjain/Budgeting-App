import 'package:flutter/material.dart';

import 'package:budgeting_app/core/design/spacing.dart';
import 'package:budgeting_app/core/widgets/app_card.dart';
import 'package:budgeting_app/core/services/app_currency_service.dart';
import 'package:budgeting_app/features/savings/domain/savings_account.dart';
import 'package:budgeting_app/features/transactions/data/transaction_repository.dart';
import 'package:budgeting_app/features/transactions/domain/transaction.dart';
import 'package:budgeting_app/features/savings/presentation/add_edit_savings_account_screen.dart';
import 'package:budgeting_app/features/savings/data/savings_account_repository.dart';

class SavingsAccountDetailScreen extends StatelessWidget {
  final SavingsAccount account;
  final SavingsAccountRepository repository;
  final TransactionRepository transactionRepository;

  const SavingsAccountDetailScreen({
    super.key,
    required this.account,
    required this.repository,
    required this.transactionRepository,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final currency = AppCurrencyService.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(account.accountNickname, style: textTheme.titleLarge),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<List<Transaction>>(
          stream: transactionRepository.watchByAccount(accountId: account.id),
          builder: (context, snapshot) {
            final txns = snapshot.data ?? const <Transaction>[];

            final currentBalance = _computeBalanceFromTxns(txns);
            final balanceText = currency.format(currentBalance);

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
                  // Top balance + edit account button (like credit card detail)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          balanceText,
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
                        onPressed: () async {
                          final changed = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => AddEditSavingsAccountScreen(
                                repository: repository,
                                transactionRepository: transactionRepository,
                                initialAccount: account,
                              ),
                            ),
                          );

                          if (changed == true) {
                            // no-op: the StreamBuilder will refresh automatically
                          }
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit account'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _HeaderCard(account: account, currentBalance: currentBalance),
                  const SizedBox(height: AppSpacing.lg),

                  Text('Account details', style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),

                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          _DetailRow(label: 'Bank', value: account.bankName),
                          _DetailRow(
                            label: 'Account number',
                            value: account.maskedAccountNumber,
                          ),
                          _DetailRow(
                            label: 'Account type',
                            value:
                                account.accountType +
                                (account.isSalaryAccount ? ' (Salary)' : ''),
                          ),
                          _DetailRow(label: 'IFSC', value: account.ifsc),
                          _DetailRow(
                            label: 'Branch',
                            value: account.branchName,
                          ),
                          _DetailRow(
                            label: 'Min. balance required',
                            value: _formatCurrency(account.minBalanceRequired),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  Text('Transactions', style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      txns.isEmpty)
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.lg,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  scheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'Loading transactions…',
                              style: textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (txns.isEmpty)
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          'No transactions yet',
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _buildTransactionTiles(
                        txns,
                        textTheme,
                        scheme,
                        currency,
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

class _HeaderCard extends StatelessWidget {
  final SavingsAccount account;
  final double currentBalance;

  const _HeaderCard({required this.account, required this.currentBalance});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final currency = AppCurrencyService.instance;

    return AppCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(AppSpacing.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${account.bankName} • ${account.maskedAccountNumber}',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onPrimary.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              currency.format(currentBalance),
              style: textTheme.headlineMedium?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const SizedBox(width: 1), // keeps alignment tidy
                _Pill(label: account.accountType),
                if (account.isSalaryAccount) ...[
                  const SizedBox(width: AppSpacing.xs),
                  const _Pill(label: 'Salary'),
                ],
              ],
            ),
          ],
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
                color: scheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Text(value, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;

  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.onPrimary.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: textTheme.bodySmall?.copyWith(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

List<Widget> _buildTransactionTiles(
  List<Transaction> txns,
  TextTheme textTheme,
  ColorScheme scheme,
  AppCurrencyService currency,
) {
  // Sort newest first
  final sorted = [...txns]
    ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

  return sorted.map((t) => _TxTile(txn: t)).toList();
}

class _TxTile extends StatelessWidget {
  final Transaction txn;

  const _TxTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final currency = AppCurrencyService.instance;

    final isOutflow = _isOutflow(txn);
    final amountPrefix = isOutflow ? '− ' : '+ ';
    final amountColor = isOutflow ? scheme.error : Colors.green.shade700;

    final description = txn.description ?? _fallbackDescription(txn.type);
    final subtitle = _buildSubtitle(txn);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: scheme.surfaceVariant,
        child: Icon(_iconForType(txn.type), size: 20, color: scheme.primary),
      ),
      title: Text(description, style: textTheme.bodyLarge),
      subtitle: Text(
        subtitle,
        style: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: Text(
        '$amountPrefix${currency.format(txn.amount)}',
        style: textTheme.bodyLarge?.copyWith(
          color: amountColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  bool _isOutflow(Transaction t) {
    switch (t.type) {
      case TransactionType.expense:
      case TransactionType.transferOut:
        return true;
      case TransactionType.income:
      case TransactionType.transferIn:
      case TransactionType.openingBalance:
        return false;
      case TransactionType.adjustment:
        return t.adjustmentDirection == AdjustmentDirection.decrease;
    }
  }

  String _buildSubtitle(Transaction t) {
    final dateLabel = _formatDate(t.bookingDate);
    final typeLabel = _fallbackDescription(t.type);
    if (t.categoryId != null && t.categoryId!.isNotEmpty) {
      return '$typeLabel • $dateLabel';
    }
    return dateLabel;
  }

  IconData _iconForType(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.arrow_downward_rounded;
      case TransactionType.expense:
        return Icons.arrow_upward_rounded;
      case TransactionType.transferIn:
        return Icons.call_received_rounded;
      case TransactionType.transferOut:
        return Icons.call_made_rounded;
      case TransactionType.openingBalance:
        return Icons.flag_outlined;
      case TransactionType.adjustment:
        return Icons.tune_outlined;
    }
  }

  String _fallbackDescription(TransactionType type) {
    switch (type) {
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
}

double _computeBalanceFromTxns(List<Transaction> txns) {
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

String _formatCurrency(double value) {
  final currency = AppCurrencyService.instance;
  return currency.format(value);
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
  final day = date.day.toString().padLeft(2, '0');
  final month = months[date.month - 1];
  final year = date.year.toString();
  return '$day $month $year';
}
