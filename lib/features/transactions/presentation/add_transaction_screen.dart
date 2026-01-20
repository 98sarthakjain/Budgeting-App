import 'package:flutter/material.dart';

import 'package:budgeting_app/core/design/spacing.dart';
import 'package:budgeting_app/core/widgets/app_card.dart';
import 'package:budgeting_app/core/services/app_currency_service.dart';

import 'package:budgeting_app/features/transactions/data/transaction_repository.dart';

import 'package:budgeting_app/features/savings/data/savings_account_repository.dart';
import 'package:budgeting_app/features/savings/domain/savings_account.dart';

import 'package:budgeting_app/features/cash/data/cash_account_repository.dart';
import 'package:budgeting_app/features/cash/domain/cash_account.dart';

import 'package:budgeting_app/features/cards/data/card_repository.dart';
import 'package:budgeting_app/features/cards/domain/credit_card.dart';

/// Manual transaction input.
///
/// **Ledger truth:** this screen writes into [TransactionRepository].
/// Balances are derived by summing transactions (see docs/global_financial_rules.md).
class AddTransactionScreen extends StatefulWidget {
  final TransactionRepository transactionRepository;
  final SavingsAccountRepository savingsRepository;
  final CashAccountRepository cashRepository;
  final CardRepository cardRepository;

  /// Optional: pre-select a kind when navigating here.
  /// Supported values: `expense`, `income`, `transfer`.
  final String? initialKind;

  /// Optional: when `initialKind == transfer`, pre-select destination as a credit card.
  final bool initialToCreditCard;

  const AddTransactionScreen({
    super.key,
    required this.transactionRepository,
    required this.savingsRepository,
    required this.cashRepository,
    required this.cardRepository,
    this.initialKind,
    this.initialToCreditCard = false,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

enum _TxnKind { expense, income, transfer }

class _CategoryOption {
  final String id;
  final String label;
  final IconData icon;

  const _CategoryOption({required this.id, required this.label, required this.icon});
}

const List<_CategoryOption> _kCategories = [
  _CategoryOption(id: 'salary', label: 'Salary', icon: Icons.payments_outlined),
  _CategoryOption(id: 'freelance', label: 'Freelance', icon: Icons.work_outline),
  _CategoryOption(id: 'food', label: 'Food', icon: Icons.restaurant_outlined),
  _CategoryOption(id: 'groceries', label: 'Groceries', icon: Icons.shopping_bag_outlined),
  _CategoryOption(id: 'transport', label: 'Transport', icon: Icons.directions_car_outlined),
  _CategoryOption(id: 'rent', label: 'Rent', icon: Icons.home_outlined),
  _CategoryOption(id: 'utilities', label: 'Utilities', icon: Icons.bolt_outlined),
  _CategoryOption(id: 'health', label: 'Health', icon: Icons.health_and_safety_outlined),
  _CategoryOption(id: 'shopping', label: 'Shopping', icon: Icons.local_mall_outlined),
  _CategoryOption(id: 'entertainment', label: 'Entertainment', icon: Icons.movie_outlined),
  _CategoryOption(id: 'travel', label: 'Travel', icon: Icons.flight_outlined),
  _CategoryOption(id: 'investment', label: 'Investment', icon: Icons.trending_up_outlined),
];


enum _AccountKind { savings, cash, creditCard }

class _AccountOption {
  final String id;
  final _AccountKind kind;
  final String label;

  const _AccountOption({
    required this.id,
    required this.kind,
    required this.label,
  });
  @override
  bool operator ==(Object other) {
    return other is _AccountOption && other.id == id && other.kind == kind;
  }

  @override
  int get hashCode => Object.hash(id, kind);

  @override
  String toString() => '_AccountOption(id: $id, kind: $kind)';
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  late _TxnKind _kind;

  _AccountOption? _selectedAccount;

  String? _selectedCategoryId;
  _AccountOption? _transferFrom;
  _AccountOption? _transferTo;

  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _kind = switch (widget.initialKind) {
      'income' => _TxnKind.income,
      'transfer' => _TxnKind.transfer,
      _ => _TxnKind.expense,
    };

    _selectedCategoryId = _kind == _TxnKind.income ? 'salary' : (_kind == _TxnKind.expense ? 'food' : null);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  List<_AccountOption> _expenseOptions(
    List<SavingsAccount> savings,
    List<CashAccount> cash,
    List<CreditCard> cards,
  ) {
    return [
      for (final a in savings)
        _AccountOption(
          id: a.id,
          kind: _AccountKind.savings,
          label: '${a.accountNickname} • ${a.bankName}',
        ),
      for (final a in cash)
        _AccountOption(
          id: a.id,
          kind: _AccountKind.cash,
          label: a.name,
        ),
      for (final c in cards)
        _AccountOption(
          id: c.id,
          kind: _AccountKind.creditCard,
          label: c.nickname,
        ),
    ];
  }

  List<_AccountOption> _incomeOptions(
    List<SavingsAccount> savings,
    List<CashAccount> cash,
  ) {
    return [
      for (final a in savings)
        _AccountOption(
          id: a.id,
          kind: _AccountKind.savings,
          label: '${a.accountNickname} • ${a.bankName}',
        ),
      for (final a in cash)
        _AccountOption(
          id: a.id,
          kind: _AccountKind.cash,
          label: a.name,
        ),
    ];
  }

  List<_AccountOption> _transferFromOptions(
    List<SavingsAccount> savings,
    List<CashAccount> cash,
  ) {
    // Transfers FROM credit cards are intentionally not supported in v1.
    return _incomeOptions(savings, cash);
  }

  List<_AccountOption> _transferToOptions(
    List<SavingsAccount> savings,
    List<CashAccount> cash,
    List<CreditCard> cards,
  ) {
    // Transfers can go TO a credit card (card payment).
    return _expenseOptions(savings, cash, cards);
  }

  void _ensureDefaults({
    required List<_AccountOption> expense,
    required List<_AccountOption> income,
    required List<_AccountOption> from,
    required List<_AccountOption> to,
  }) {
    // Single-entry (expense/income)
    if (_kind == _TxnKind.expense && _selectedAccount == null) {
      _selectedAccount = expense.isNotEmpty ? expense.first : null;
    }
    if (_kind == _TxnKind.income && _selectedAccount == null) {
      _selectedAccount = income.isNotEmpty ? income.first : null;
    }

    // Transfer defaults
    _transferFrom ??= from.isNotEmpty ? from.first : null;

    if (_transferTo == null) {
      if (widget.initialToCreditCard) {
        final firstCard = to.firstWhere(
          (o) => o.kind == _AccountKind.creditCard,
          orElse: () => to.isNotEmpty ? to.first : const _AccountOption(id: '', kind: _AccountKind.savings, label: ''),
        );
        _transferTo = firstCard.id.isEmpty ? null : firstCard;
      } else {
        _transferTo = to.isNotEmpty ? to.first : null;
      }
    }

    // If user switches kind, keep things sane.
    if ((_kind == _TxnKind.expense || _kind == _TxnKind.income) &&
        _selectedAccount == null) {
      _selectedAccount = (_kind == _TxnKind.expense)
          ? (expense.isNotEmpty ? expense.first : null)
          : (income.isNotEmpty ? income.first : null);
    }
  }

  Future<void> _save({
    required List<_AccountOption> expenseOptions,
    required List<_AccountOption> incomeOptions,
    required List<_AccountOption> transferFromOptions,
    required List<_AccountOption> transferToOptions,
  }) async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final amount =
          double.tryParse(_amountController.text.replaceAll(',', '').trim()) ??
              0;
      final desc = _descController.text.trim();
      final now = DateTime.now();

      if (_kind == _TxnKind.income) {
        final target = _selectedAccount ??
            (incomeOptions.isNotEmpty ? incomeOptions.first : null);
        if (target == null) {
          _showSnack('Create a savings/cash account first.');
          return;
        }

        await widget.transactionRepository.createIncome(
          accountId: target.id,
          amount: amount,
          bookingDate: now,
          categoryId: _selectedCategoryId,
          description: desc.isEmpty ? 'Income' : desc,
        );
      } else if (_kind == _TxnKind.expense) {
        final source = _selectedAccount ??
            (expenseOptions.isNotEmpty ? expenseOptions.first : null);
        if (source == null) {
          _showSnack('Create an account first.');
          return;
        }

        await widget.transactionRepository.createExpense(
          accountId: source.id,
          amount: amount,
          bookingDate: now,
          categoryId: _selectedCategoryId,
          description: desc.isEmpty ? 'Expense' : desc,
        );
      } else {
        // Transfer (incl. card payment)
        final from = _transferFrom ??
            (transferFromOptions.isNotEmpty ? transferFromOptions.first : null);
        final to = _transferTo ??
            (transferToOptions.isNotEmpty ? transferToOptions.first : null);

        if (from == null || to == null) {
          _showSnack('Create accounts first (savings/cash, and optionally a card).');
          return;
        }

        if (from.id == to.id) {
          _showSnack('From and To accounts cannot be the same.');
          return;
        }

        final defaultLabel =
            (to.kind == _AccountKind.creditCard) ? 'Card payment' : 'Transfer';

        await widget.transactionRepository.createTransfer(
          fromAccountId: from.id,
          toAccountId: to.id,
          amount: amount,
          bookingDate: now,
          description: desc.isEmpty ? defaultLabel : desc,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currency = AppCurrencyService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Add transaction')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: StreamBuilder<List<SavingsAccount>>(
            stream: widget.savingsRepository.watchAllAccounts(),
            initialData: const [],
            builder: (context, savingsSnap) {
              return StreamBuilder<List<CashAccount>>(
                stream: widget.cashRepository.watchAllAccounts(),
                initialData: const [],
                builder: (context, cashSnap) {
                  return StreamBuilder<List<CreditCard>>(
                    stream: widget.cardRepository.watchAllCards(),
                    initialData: const [],
                    builder: (context, cardSnap) {
                      final savings = savingsSnap.data ?? const [];
                      final cash = cashSnap.data ?? const [];
                      final cards = cardSnap.data ?? const [];

                      final expenseOptions = _expenseOptions(savings, cash, cards);
                      final incomeOptions = _incomeOptions(savings, cash);
                      final transferFromOptions =
                          _transferFromOptions(savings, cash);
                      final transferToOptions =
                          _transferToOptions(savings, cash, cards);

                      _ensureDefaults(
                        expense: expenseOptions,
                        income: incomeOptions,
                        from: transferFromOptions,
                        to: transferToOptions,
                      );

                      return Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  children: [
// Kind toggle
                            AppCard(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ChoiceChip(
                                        label: const Text('Expense'),
                                        selected: _kind == _TxnKind.expense,
                                        onSelected: (_) {
                                          setState(() {
                                            final previous = _kind;
                                            _kind = _TxnKind.expense;
                                            _selectedAccount = null;
                                            if (previous != _TxnKind.expense) {
                                              _selectedCategoryId = 'food';
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: ChoiceChip(
                                        label: const Text('Income'),
                                        selected: _kind == _TxnKind.income,
                                        onSelected: (_) {
                                          setState(() {
                                            final previous = _kind;
                                            _kind = _TxnKind.income;
                                            _selectedAccount = null;
                                            if (previous != _TxnKind.income) {
                                              _selectedCategoryId = 'salary';
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: ChoiceChip(
                                        label: const Text('Transfer'),
                                        selected: _kind == _TxnKind.transfer,
                                        onSelected: (_) {
                                          setState(() {
                                            _kind = _TxnKind.transfer;
                                            _selectedCategoryId = null;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            if (_kind != _TxnKind.transfer) ...[
                              _CategoryPickerCard(
                                selectedId: _selectedCategoryId ??
                                    (_kind == _TxnKind.income
                                        ? 'salary'
                                        : 'food'),
                                onChanged: (v) {
                                  setState(() {
                                    _selectedCategoryId = v;
                                  });
                                },
                              ),
                              const SizedBox(height: AppSpacing.lg),
                            ],

                            // Amount
                            TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                prefixText: '${currency.baseSymbol} ',
                              ),
                              validator: (v) {
                                final n = double.tryParse(
                                  (v ?? '').replaceAll(',', '').trim(),
                                );
                                if (n == null || n <= 0) {
                                  return 'Enter a valid amount';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Description
                            TextFormField(
                              controller: _descController,
                              decoration: const InputDecoration(
                                labelText: 'Description (optional)',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                switch (_kind) {
                                  _TxnKind.income => 'Deposit into',
                                  _TxnKind.expense => 'Paid via',
                                  _TxnKind.transfer => 'Transfer',
                                },
                                style: textTheme.titleMedium,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),

                            if (_kind == _TxnKind.transfer)
                              _TransferPickerCard(
                                fromOptions: transferFromOptions,
                                toOptions: transferToOptions,
                                fromValue: _transferFrom,
                                toValue: _transferTo,
                                onChangedFrom: (v) {
                                  setState(() {
                                    _transferFrom = v;
                                    // Prevent same-to-same silently
                                    if (_transferTo?.id == v?.id) {
                                      _transferTo = null;
                                    }
                                  });
                                },
                                onChangedTo: (v) {
                                  setState(() => _transferTo = v);
                                },
                              )
                            else
                              _SingleAccountPickerCard(
                                title: _kind == _TxnKind.income
                                    ? 'Receive into'
                                    : 'Pay from',
                                options: _kind == _TxnKind.income
                                    ? incomeOptions
                                    : expenseOptions,
                                value: _selectedAccount,
                                onChanged: (v) {
                                  setState(() => _selectedAccount = v);
                                },
                              ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(

                                onPressed: _isSaving
                                    ? null
                                    : () => _save(
                                          expenseOptions: expenseOptions,
                                          incomeOptions: incomeOptions,
                                          transferFromOptions: transferFromOptions,
                                          transferToOptions: transferToOptions,
                                        ),
                                child: _isSaving
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SingleAccountPickerCard extends StatelessWidget {
  final String title;
  final List<_AccountOption> options;
  final _AccountOption? value;
  final ValueChanged<_AccountOption?> onChanged;

  const _SingleAccountPickerCard({
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            if (options.isEmpty)
              const Text('No accounts yet')
            else
              DropdownButtonFormField<_AccountOption>(
                value: value ?? options.first,
                items: [
                  for (final o in options)
                    DropdownMenuItem(value: o, child: Text(o.label)),
                ],
                onChanged: onChanged,
              ),
          ],
        ),
      ),
    );
  }
}


class _CategoryPickerCard extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _CategoryPickerCard({required this.selectedId, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              value: selectedId,
              items: [
                for (final c in _kCategories)
                  DropdownMenuItem<String>(
                    value: c.id,
                    child: Row(
                      children: [
                        Icon(c.icon, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Text(c.label),
                      ],
                    ),
                  ),
              ],
              onChanged: onChanged,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferPickerCard extends StatelessWidget {
  final List<_AccountOption> fromOptions;
  final List<_AccountOption> toOptions;
  final _AccountOption? fromValue;
  final _AccountOption? toValue;
  final ValueChanged<_AccountOption?> onChangedFrom;
  final ValueChanged<_AccountOption?> onChangedTo;

  const _TransferPickerCard({
    required this.fromOptions,
    required this.toOptions,
    required this.fromValue,
    required this.toValue,
    required this.onChangedFrom,
    required this.onChangedTo,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From', style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            if (fromOptions.isEmpty)
              const Text('No savings/cash accounts yet')
            else
              DropdownButtonFormField<_AccountOption>(
                value: fromValue ?? fromOptions.first,
                items: [
                  for (final o in fromOptions)
                    DropdownMenuItem(value: o, child: Text(o.label)),
                ],
                onChanged: onChangedFrom,
              ),
            const SizedBox(height: AppSpacing.md),
            Text('To', style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            if (toOptions.isEmpty)
              const Text('No destination accounts yet')
            else
              DropdownButtonFormField<_AccountOption>(
                value: toValue ?? toOptions.first,
                items: [
                  for (final o in toOptions)
                    DropdownMenuItem(value: o, child: Text(o.label)),
                ],
                onChanged: onChangedTo,
              ),
          ],
        ),
      ),
    );
  }
}
