import 'package:flutter/material.dart';

import 'package:budgeting_app/core/design/spacing.dart';
import 'package:budgeting_app/core/widgets/app_card.dart';
import 'package:budgeting_app/core/services/app_currency_service.dart';
import 'package:budgeting_app/features/cash/domain/cash_account.dart';
import 'package:budgeting_app/features/cash/data/cash_account_repository.dart';
import 'package:budgeting_app/features/cash/presentation/cash_account_detail_screen.dart';
import 'package:budgeting_app/features/cash/presentation/add_edit_wallet_screen.dart';
import 'package:budgeting_app/features/transactions/data/transaction_repository.dart';

class CashAccountsScreen extends StatefulWidget {
  final CashAccountRepository repository;
  final TransactionRepository transactionRepository;

  const CashAccountsScreen({
    super.key,
    required this.repository,
    required this.transactionRepository,
  });

  @override
  State<CashAccountsScreen> createState() => _CashAccountsScreenState();
}

class _CashAccountsScreenState extends State<CashAccountsScreen> {
  late Future<_CashData> _future;
  bool _showClosedWallets = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_CashData> _load() async {
    final accounts = await widget.repository.getAllAccounts(
      includeClosed: true,
    );
    final cash = await widget.repository.getCashAccount();
    return _CashData(accounts: accounts, cash: cash);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _onAddWallet() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddEditWalletScreen(
          repository: widget.repository,
          transactionRepository: widget.transactionRepository,
        ),
      ),
    );

    if (changed == true) {
      await _refresh();
    }
  }

  Future<void> _onEditWallet(CashAccount wallet) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddEditWalletScreen(
          repository: widget.repository,
          transactionRepository: widget.transactionRepository,
          initialWallet: wallet,
        ),
      ),
    );

    if (changed == true) {
      await _refresh();
    }
  }

  Future<void> _openAccountDetail(CashAccount account) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CashAccountDetailScreen(
          account: account,
          transactionRepository: widget.transactionRepository,
        ),
      ),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cash & wallets', style: textTheme.titleLarge),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddWallet,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FutureBuilder<_CashData>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load cash & wallets',
                      style: textTheme.bodyMedium,
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data!;
              final allAccounts = data.accounts;
              final cash = data.cash;

              // Separate wallets (everything except the cash-in-hand account)
              final allWallets = allAccounts
                  .where((a) => a.id != cash.id)
                  .toList(growable: false);

              final openWallets = allWallets
                  .where((w) => !w.isClosed)
                  .toList(growable: false);
              final closedWallets = allWallets
                  .where((w) => w.isClosed)
                  .toList(growable: false);

              final wallets = _showClosedWallets ? allWallets : openWallets;

              // Total should only include open accounts
              final total = allAccounts
                  .where((a) => !a.isClosed)
                  .fold<double>(0, (s, a) => s + a.balance);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TotalCashCard(total: total),
                  const SizedBox(height: AppSpacing.lg),

                  // Cash in hand section
                  Text('Cash in hand', style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                      onTap: () => _openAccountDetail(cash),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: _CashOrWalletRow(
                          account: cash,
                          isCash: true,
                          onEdit: null, // Cash not edited via this flow
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Wallets section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Wallets', style: textTheme.titleMedium),
                      Row(
                        children: [
                          if (closedWallets.isNotEmpty) ...[
                            Text(
                              _showClosedWallets
                                  ? 'Showing closed'
                                  : 'Hide closed',
                              style: textTheme.bodySmall,
                            ),
                            Switch(
                              value: _showClosedWallets,
                              onChanged: (value) {
                                setState(() {
                                  _showClosedWallets = value;
                                });
                              },
                            ),
                          ],
                          TextButton.icon(
                            onPressed: _onAddWallet,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add wallet'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  if (wallets.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        'No wallets added yet.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(((0.7) * 255).round()),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: wallets.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final wallet = wallets[index];
                          return AppCard(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.md,
                              ),
                              onTap: () => _openAccountDetail(wallet),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: _CashOrWalletRow(
                                  account: wallet,
                                  isCash: false,
                                  onEdit: () => _onEditWallet(wallet),
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

class _CashData {
  final List<CashAccount> accounts;
  final CashAccount cash;

  const _CashData({required this.accounts, required this.cash});
}

class _TotalCashCard extends StatelessWidget {
  final double total;

  const _TotalCashCard({required this.total});

  @override
  Widget build(BuildContext context) {
    final currency = AppCurrencyService.instance;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total cash & wallets',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSecondaryContainer.withAlpha(((0.9) * 255).round()),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              currency.format(total),
              style: textTheme.headlineMedium?.copyWith(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashOrWalletRow extends StatelessWidget {
  final CashAccount account;
  final bool isCash;
  final VoidCallback? onEdit;

  const _CashOrWalletRow({
    required this.account,
    required this.isCash,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currency = AppCurrencyService.instance;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        _Avatar(isCash: isCash),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.name,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
        Text(
          currency.format(account.balance),
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (onEdit != null) ...[
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: onEdit,
            tooltip: 'Edit wallet',
          ),
        ],
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final bool isCash;

  const _Avatar({required this.isCash});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = isCash ? Icons.payments : Icons.account_balance_wallet;

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
