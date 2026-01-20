import 'package:flutter/material.dart';

import 'package:budgeting_app/core/design/spacing.dart';
import 'package:budgeting_app/core/widgets/app_card.dart';
import 'package:budgeting_app/core/services/app_currency_service.dart';
import 'package:budgeting_app/features/loans/data/loan_account_repository.dart';
import 'package:budgeting_app/features/loans/domain/loan_account.dart';
import 'package:budgeting_app/features/loans/presentation/loan_account_detail_screen.dart';

class LoanAccountsScreen extends StatefulWidget {
  final LoanAccountRepository repository;

  const LoanAccountsScreen({super.key, required this.repository});

  @override
  State<LoanAccountsScreen> createState() => _LoanAccountsScreenState();
}

class _LoanAccountsScreenState extends State<LoanAccountsScreen> {
  late Future<List<LoanAccount>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getAllLoans();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currency = AppCurrencyService.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text('Loans', style: textTheme.titleLarge),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FutureBuilder<List<LoanAccount>>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Could not load loans',
                      style: textTheme.bodyMedium,
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              }

              final loans = snapshot.data!;
              final totalOutstanding = loans.fold<double>(
                0,
                (sum, l) => sum + l.outstandingPrincipal,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TotalOutstandingCard(total: totalOutstanding),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Loan accounts', style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: ListView.separated(
                      itemCount: loans.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final loan = loans[index];
                        return AppCard(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppSpacing.md),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      LoanAccountDetailScreen(loan: loan),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                children: [
                                  _LoanAvatar(loanType: loan.loanType),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          loan.loanNickname,
                                          style: textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          '${loan.bankName} • ${loan.maskedAccountNumber}',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withAlpha(((0.7) * 255).round()),
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          'EMI ${currency.format(loan.emiAmount)} • ${loan.remainingTenureMonths} months left',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withAlpha(((0.7) * 255).round()),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        currency.format(
                                          loan.outstandingPrincipal,
                                        ),
                                        style: textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        '${loan.interestRateAnnual.toStringAsFixed(2)}% p.a.',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withAlpha(((0.7) * 255).round()),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TotalOutstandingCard extends StatelessWidget {
  final double total;

  const _TotalOutstandingCard({required this.total});

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
          color: scheme.errorContainer.withAlpha(((0.35) * 255).round()),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total loan outstanding',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onErrorContainer.withAlpha(((0.9) * 255).round()),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              currency.format(total),
              style: textTheme.headlineMedium?.copyWith(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanAvatar extends StatelessWidget {
  final String loanType;

  const _LoanAvatar({required this.loanType});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    IconData icon;
    switch (loanType.toLowerCase()) {
      case 'home':
        icon = Icons.home_outlined;
        break;
      case 'car':
        icon = Icons.directions_car;
        break;
      default:
        icon = Icons.account_balance;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: scheme.primary, size: 22),
    );
  }
}
