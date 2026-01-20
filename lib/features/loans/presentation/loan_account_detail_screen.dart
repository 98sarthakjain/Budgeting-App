import 'package:flutter/material.dart';

import 'package:budgeting_app/core/design/spacing.dart';
import 'package:budgeting_app/core/widgets/app_card.dart';
import 'package:budgeting_app/core/services/app_currency_service.dart';
import 'package:budgeting_app/features/loans/domain/loan_account.dart';
import 'package:budgeting_app/features/loans/presentation/loan_prepayment_planner_screen.dart';

class LoanAccountDetailScreen extends StatelessWidget {
  final LoanAccount loan;

  const LoanAccountDetailScreen({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currency = AppCurrencyService.instance;
    final outstandingText = currency.format(loan.outstandingPrincipal);

    // Dummy EMI history for
    final recentEmis = [
      _EmiItem(
        label: 'EMI paid',
        dateLabel: _formatDate(loan.lastEmiPaidDate),
        amount: loan.lastEmiAmount,
      ),
      _EmiItem(
        label: 'EMI paid',
        dateLabel: _formatDate(
          loan.lastEmiPaidDate.subtract(const Duration(days: 30)),
        ),
        amount: loan.lastEmiAmount,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Loan details', style: textTheme.titleLarge),
        centerTitle: true,
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
              // Top outstanding + Plan prepayment button
              Row(
                children: [
                  Expanded(
                    child: Text(
                      outstandingText,
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
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              LoanPrepaymentPlannerScreen(loan: loan),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calculate_outlined, size: 18),
                    label: const Text('Plan prepayment'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              _LoanHeaderCard(loan: loan),
              const SizedBox(height: AppSpacing.lg),

              Text('Loan summary', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),

              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      _DetailRow(label: 'Bank', value: loan.bankName),
                      _DetailRow(label: 'Loan type', value: loan.loanType),
                      _DetailRow(
                        label: 'Account no.',
                        value: loan.maskedAccountNumber,
                      ),
                      _DetailRow(
                        label: 'Principal',
                        value: currency.format(loan.principalAmount),
                      ),
                      _DetailRow(
                        label: 'Outstanding principal',
                        value: currency.format(loan.outstandingPrincipal),
                      ),
                      _DetailRow(
                        label: 'Interest rate',
                        value:
                            '${loan.interestRateAnnual.toStringAsFixed(2)}% p.a.',
                      ),
                      _DetailRow(
                        label: 'Rate type',
                        value: loan.rateType == LoanRateType.fixed
                            ? 'Fixed'
                            : 'Floating',
                      ),
                      _DetailRow(
                        label: 'EMI',
                        value: currency.format(loan.emiAmount),
                      ),
                      _DetailRow(
                        label: 'Tenure',
                        value:
                            '${loan.originalTenureMonths} months (${loan.remainingTenureMonths} left)',
                      ),
                      _DetailRow(
                        label: 'Next EMI',
                        value:
                            '${currency.format(loan.emiAmount)} on ${_formatDate(loan.nextEmiDueDate)}',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Text('Recent EMIs', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      for (final emi in recentEmis) _EmiTile(item: emi),
                    ],
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

class _LoanHeaderCard extends StatelessWidget {
  final LoanAccount loan;

  const _LoanHeaderCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currency = AppCurrencyService.instance;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loan.loanNickname,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${loan.bankName} • ${loan.maskedAccountNumber}',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withAlpha(((0.7) * 255).round()),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  'EMI ${currency.format(loan.emiAmount)}',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${loan.remainingTenureMonths} months left',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withAlpha(((0.7) * 255).round()),
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

class _EmiItem {
  final String label;
  final String dateLabel;
  final double amount;

  const _EmiItem({
    required this.label,
    required this.dateLabel,
    required this.amount,
  });
}

class _EmiTile extends StatelessWidget {
  final _EmiItem item;

  const _EmiTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currency = AppCurrencyService.instance;
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: scheme.surfaceContainerHighest,
        child: Icon(Icons.currency_rupee, size: 18, color: scheme.primary),
      ),
      title: Text(item.label, style: textTheme.bodyLarge),
      subtitle: Text(
        item.dateLabel,
        style: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface.withAlpha(((0.7) * 255).round()),
        ),
      ),
      trailing: Text(
        currency.format(item.amount),
        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
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
  final y = date.year.toString();
  return '$d $m $y';
}
