import 'package:flutter/material.dart';

import 'package:budgeting_app/core/design/spacing.dart';
import 'package:budgeting_app/core/widgets/app_card.dart';
import 'package:budgeting_app/core/services/app_currency_service.dart';
import 'package:budgeting_app/features/insurance/domain/insurance_policy.dart';

class InsuranceDetailScreen extends StatelessWidget {
  final InsurancePolicy policy;

  const InsuranceDetailScreen({super.key, required this.policy});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final currency = AppCurrencyService.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(policy.policyName, style: textTheme.titleLarge),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Open policy settings
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              AppCard(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        policy.insurerName,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onPrimary.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        policy.policyName,
                        style: textTheme.titleMedium?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Premium: ${currency.format(policy.premiumAmount)}',
                        style: textTheme.bodyLarge?.copyWith(
                          color: scheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Text('Policy details', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),

              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Policy number',
                        value: policy.policyNumber,
                      ),
                      _DetailRow(
                        label: 'Type',
                        value: _typeToString(policy.type),
                      ),
                      _DetailRow(
                        label: 'Expiry date',
                        value: _formatDate(policy.expiryDate),
                      ),
                      _DetailRow(
                        label: 'Sum insured',
                        value: currency.format(policy.sumInsured),
                      ),
                      _DetailRow(
                        label: 'Auto-renew',
                        value: policy.autoRenew ? 'Enabled' : 'Disabled',
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

String _typeToString(InsuranceType type) {
  switch (type) {
    case InsuranceType.health:
      return 'Health';
    case InsuranceType.life:
      return 'Life';
    case InsuranceType.term:
      return 'Term';
    case InsuranceType.motor:
      return 'Motor';
    case InsuranceType.travel:
      return 'Travel';
    default:
      return 'Home';
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
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
