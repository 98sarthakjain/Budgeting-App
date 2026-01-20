import 'dart:async';

import 'package:flutter/material.dart';

import 'package:budgeting_app/core/design/spacing.dart';
import 'package:budgeting_app/core/widgets/app_card.dart';
import 'package:budgeting_app/core/services/app_currency_service.dart';
import 'package:budgeting_app/features/savings/data/savings_account_repository.dart';
import 'package:budgeting_app/features/savings/domain/savings_account.dart';
import 'package:budgeting_app/features/savings/presentation/savings_account_detail_screen.dart';
import 'package:budgeting_app/features/savings/presentation/add_edit_savings_account_screen.dart';
import 'package:budgeting_app/features/transactions/data/transaction_repository.dart';

class SavingsAccountsScreen extends StatefulWidget {
  final SavingsAccountRepository repository;
  final TransactionRepository transactionRepository;

  const SavingsAccountsScreen({
    super.key,
    required this.repository,
    required this.transactionRepository,
  });

  @override
  State<SavingsAccountsScreen> createState() => _SavingsAccountsScreenState();
}

class _SavingsAccountsScreenState extends State<SavingsAccountsScreen> {
  bool _showClosed = false;
  late Future<List<SavingsAccount>> _future;
  late StreamSubscription _txnSub;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getAllAccounts(includeClosed: true);
  }

  Future<void> _reloadAccounts() async {
    setState(() {
      _future = widget.repository.getAllAccounts(includeClosed: true);
    });
  }

  Future<void> _onAddAccount() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddEditSavingsAccountScreen(
          repository: widget.repository,
          transactionRepository: widget.transactionRepository,
        ),
      ),
    );

    // If the screen returned true, user saved something -> refresh list.
    if (result == true && mounted) {
      await _reloadAccounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Savings accounts', style: textTheme.titleLarge),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddAccount,
        icon: const Icon(Icons.add),
        label: const Text('Add account'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FutureBuilder<List<SavingsAccount>>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Could not load accounts',
                      style: textTheme.bodyMedium,
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              }

              final allAccounts = snapshot.data!;
              if (allAccounts.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _TotalBalanceCard.empty(),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Accounts', style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: Center(
                        child: Text(
                          'No savings accounts yet',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                );
              }

              // Split into open vs closed
              final openAccounts = allAccounts
                  .where((a) => !a.isClosed)
                  .toList(growable: false);
              final closedAccounts = allAccounts
                  .where((a) => a.isClosed)
                  .toList(growable: false);

              final visibleAccounts = _showClosed ? allAccounts : openAccounts;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TotalBalanceCard(
                    // Total should only consider open accounts
                    accounts: openAccounts,
                    transactionRepository: widget.transactionRepository,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Header + toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Accounts', style: textTheme.titleMedium),
                      if (closedAccounts.isNotEmpty)
                        Row(
                          children: [
                            Text(
                              _showClosed ? 'Showing closed' : 'Hide closed',
                              style: textTheme.bodySmall,
                            ),
                            Switch(
                              value: _showClosed,
                              onChanged: (value) {
                                setState(() {
                                  _showClosed = value;
                                });
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  Expanded(
                    child: ListView.separated(
                      itemCount: visibleAccounts.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final account = visibleAccounts[index];
                        return _SavingsAccountTile(
                          account: account,
                          transactionRepository: widget.transactionRepository,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SavingsAccountDetailScreen(
                                  account: account,
                                  transactionRepository:
                                      widget.transactionRepository,
                                  repository: widget.repository,
                                ),
                              ),
                            );
                          },
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

class _TotalBalanceCard extends StatelessWidget {
  final List<SavingsAccount>? accounts;
  final TransactionRepository? transactionRepository;

  const _TotalBalanceCard({this.accounts, this.transactionRepository});

  /// Convenience for the "no accounts" state.
  const _TotalBalanceCard.empty()
    : accounts = null,
      transactionRepository = null;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final currency = AppCurrencyService.instance;

    Widget buildInner(double totalBalance, {bool isLoading = false}) {
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
                'Total savings',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onPrimary.withAlpha(((0.9) * 255).round()),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (isLoading)
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          scheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Calculating…',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimary.withAlpha(((0.9) * 255).round()),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  currency.format(totalBalance),
                  style: textTheme.headlineMedium?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // If no accounts yet, just show zero without extra async work.
    if (accounts == null ||
        accounts!.isEmpty ||
        transactionRepository == null) {
      return buildInner(0);
    }

    // Compute total balance from ledger using computeBalance for each account.
    final accountsList = accounts!;
    final repo = transactionRepository!;

    return FutureBuilder<List<double>>(
      future: Future.wait(
        accountsList.map((a) => repo.computeBalance(accountId: a.id)),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) {
            // Fallback to 0 with subtle hint
            return buildInner(0);
          }
          return buildInner(0, isLoading: true);
        }

        final balances = snapshot.data!;
        final totalBalance = balances.fold<double>(0, (sum, b) => sum + b);

        return buildInner(totalBalance);
      },
    );
  }
}

class _SavingsAccountTile extends StatelessWidget {
  final SavingsAccount account;
  final TransactionRepository transactionRepository;
  final VoidCallback onTap;

  const _SavingsAccountTile({
    required this.account,
    required this.transactionRepository,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final currency = AppCurrencyService.instance;

    return AppCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Leading avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(((0.08) * 255).round()),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance,
                  color: scheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.accountNickname,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${account.bankName} • ${account.maskedAccountNumber}',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(((0.7) * 255).round()),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        _Pill(label: account.accountType),
                        if (account.isSalaryAccount) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const _Pill(label: 'Salary'),
                        ],
                      ],
                    ),
                    if (account.isClosed) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Closed',
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Balance (from ledger)
              FutureBuilder<double>(
                future: transactionRepository.computeBalance(
                  accountId: account.id,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          scheme.primary,
                        ),
                      ),
                    );
                  }

                  final balance = snapshot.data ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currency.format(balance),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Available',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withAlpha(((0.6) * 255).round()),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
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
        color: scheme.primary.withAlpha(((0.08) * 255).round()),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: textTheme.bodySmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
