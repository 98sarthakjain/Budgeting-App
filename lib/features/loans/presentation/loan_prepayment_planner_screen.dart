import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:budgeting_app/core/design/spacing.dart';
import 'package:budgeting_app/core/widgets/app_card.dart';
import 'package:budgeting_app/core/services/app_currency_service.dart';
import 'package:budgeting_app/features/loans/domain/loan_account.dart';

class LoanPrepaymentPlannerScreen extends StatefulWidget {
  final LoanAccount loan;

  const LoanPrepaymentPlannerScreen({super.key, required this.loan});

  @override
  State<LoanPrepaymentPlannerScreen> createState() =>
      _LoanPrepaymentPlannerScreenState();
}

class _LoanPrepaymentPlannerScreenState
    extends State<LoanPrepaymentPlannerScreen> {
  late TextEditingController _rateController;
  late TextEditingController _prepayController;

  late double _newRate;
  late double _prepayment;

  @override
  void initState() {
    super.initState();
    _newRate = widget.loan.interestRateAnnual;
    _prepayment = 0;

    _rateController = TextEditingController(text: _newRate.toStringAsFixed(2));
    _prepayController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _rateController.dispose();
    _prepayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final currency = AppCurrencyService.instance;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    // Inputs
    final outstanding = loan.outstandingPrincipal;
    final emi = loan.emiAmount;

    final double newPrincipal = (outstanding - _prepayment)
        .clamp(0.0, outstanding)
        .toDouble();

    final oldRemaining = loan.remainingTenureMonths;
    final newRemaining = _computeNewTenureMonths(
      principal: newPrincipal,
      annualRatePercent: _newRate,
      emi: emi,
      fallbackTenureMonths: oldRemaining,
    );

    final int monthsSaved = math.max(0, oldRemaining - newRemaining);
    final now = DateTime.now();
    final oldEndDate = DateTime(now.year, now.month + oldRemaining, now.day);
    final newEndDate = DateTime(now.year, now.month + newRemaining, now.day);

    return Scaffold(
      appBar: AppBar(
        title: Text('Plan prepayment', style: textTheme.titleLarge),
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
              const SizedBox(height: AppSpacing.lg),

              // Current situation
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current situation',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _InlineInfoRow(
                        label: 'Outstanding principal',
                        value: currency.format(outstanding),
                      ),
                      _InlineInfoRow(
                        label: 'Current rate',
                        value:
                            '${loan.interestRateAnnual.toStringAsFixed(2)}% p.a.',
                      ),
                      _InlineInfoRow(
                        label: 'EMI',
                        value: currency.format(loan.emiAmount),
                      ),
                      _InlineInfoRow(
                        label: 'Remaining tenure',
                        value: '$oldRemaining months',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Adjust assumptions
              Text('Adjust assumptions', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),

              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New interest rate (floating)',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        controller: _rateController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 8.10',
                          suffixText: '% p.a.',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _newRate =
                                double.tryParse(value) ??
                                loan.interestRateAnnual;
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'One-time prepayment now',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        controller: _prepayController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. ${currency.format(100000)}',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _prepayment = double.tryParse(value) ?? 0.0;
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'New principal after prepayment: '
                        '${currency.format(newPrincipal)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withAlpha(((0.7) * 255).round()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Impact on tenure
              Text('Impact on tenure', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),

              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InlineInfoRow(
                        label: 'New remaining tenure',
                        value:
                            '$newRemaining months (${_formatYearsMonths(newRemaining)})',
                      ),
                      _InlineInfoRow(
                        label: 'Tenure reduced by',
                        value: '$monthsSaved months',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _InlineInfoRow(
                        label: 'Old end date',
                        value: _formatDate(oldEndDate),
                      ),
                      _InlineInfoRow(
                        label: 'New end date',
                        value: _formatDate(newEndDate),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Planner only for now.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'This is a planning tool right now. '
                          'In a later version this can update the actual loan.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Save this as my plan (future)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Computes remaining tenure in months for a given principal, rate, and EMI
  /// assuming EMI stays constant and rate is per annum (%).
  int _computeNewTenureMonths({
    required double principal,
    required double annualRatePercent,
    required double emi,
    required int fallbackTenureMonths,
  }) {
    if (principal <= 0) return 0;
    if (annualRatePercent <= 0) {
      // Simple fallback: principal / emi (no interest).
      final n = (principal / emi).ceil();
      return n > 0 ? n : fallbackTenureMonths;
    }

    final r = annualRatePercent / 12.0 / 100.0; // monthly rate

    // EMI must be > interest per month, else math breaks.
    if (emi <= principal * r) {
      return fallbackTenureMonths;
    }

    // n = log(EMI / (EMI - P*r)) / log(1 + r)
    final numerator = math.log(emi / (emi - principal * r));
    final denominator = math.log(1 + r);

    if (denominator == 0) return fallbackTenureMonths;

    final n = (numerator / denominator).ceil();
    if (n.isNaN || n.isInfinite || n <= 0) {
      return fallbackTenureMonths;
    }
    return n;
  }
}

class _InlineInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InlineInfoRow({required this.label, required this.value});

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
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
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

String _formatYearsMonths(int totalMonths) {
  final years = totalMonths ~/ 12;
  final months = totalMonths % 12;
  if (years == 0) return '$months months';
  if (months == 0) return '$years years';
  return '$years years $months months';
}
