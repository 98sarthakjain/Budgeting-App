import 'package:flutter/material.dart';

import 'package:budgeting_app/core/design/spacing.dart';
import 'package:budgeting_app/core/widgets/app_card.dart';
import 'package:budgeting_app/core/services/app_currency_service.dart';
import 'package:budgeting_app/features/investments/domain/investment_account.dart';

class InvestmentDetailScreen extends StatelessWidget {
  final InvestmentAccount account;

  const InvestmentDetailScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currency = AppCurrencyService.instance;
    final scheme = Theme.of(context).colorScheme;

    final isGain = account.profitLoss >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name, style: textTheme.titleLarge),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              AppCard(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.institution,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onPrimary.withAlpha(((0.9) * 255).round()),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        account.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Current value: ${currency.format(account.currentValue)}',
                        style: textTheme.bodyLarge?.copyWith(
                          color: scheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Invested: ${currency.format(account.investedAmount)}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${isGain ? "+" : "-"}${currency.format(account.profitLoss.abs())}  •  ${account.xirr.toStringAsFixed(2)}% p.a.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: isGain ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text('Investment details', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),

              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      _DetailRow(label: 'Category', value: account.category),
                      _DetailRow(
                        label: 'Institution',
                        value: account.institution,
                      ),
                      if (account.folioNumber != null)
                        _DetailRow(
                          label: 'Folio No.',
                          value: account.folioNumber!,
                        ),
                      _DetailRow(
                        label: 'XIRR',
                        value: '${account.xirr.toStringAsFixed(2)}% p.a.',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
