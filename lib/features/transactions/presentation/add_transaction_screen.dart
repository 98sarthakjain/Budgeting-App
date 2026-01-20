import 'package:flutter/material.dart';

import 'package:budgeting_app/core/design/spacing.dart';
import 'package:budgeting_app/core/widgets/app_card.dart';
import 'package:budgeting_app/core/services/account_store.dart';
import 'package:budgeting_app/core/services/card_store.dart';
import 'package:budgeting_app/core/services/ledger_transaction_store.dart';

import 'package:budgeting_app/features/savings/domain/account.dart'; // ⬅️ add this
import 'package:budgeting_app/features/cards/domain/credit_card.dart'; // ⬅️ and this

import '../domain/transaction.dart'; // existing Hive Transaction model (not used yet)
import '../data/transaction_repository.dart'; // keep constructor compatible

import '../domain/ledger_entry.dart';

class AddTransactionScreen extends StatefulWidget {
  /// Keep this so old navigation code that passes a repo still compiles.
  final TransactionRepository? txRepo;

  const AddTransactionScreen({super.key, this.txRepo});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  bool _isExpense = true;

  // For expense
  LedgerPaymentMode _expenseMode = LedgerPaymentMode.savingsAccount;
  String? _selectedExpenseSourceId; // accountId or cardId depending on mode

  // For income (goes into an account)
  String? _selectedIncomeAccountId; // savings or cash account

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountStore = AccountStore.instance;
    final cardStore = CardStore.instance;

    final savingsAccounts = accountStore.savingsAccounts;
    final cashAccounts = accountStore.cashAccounts;
    final cards = cardStore.cards;

    // Make sure default selections exist so the form works quickly.
    _selectedExpenseSourceId ??= () {
      switch (_expenseMode) {
        case LedgerPaymentMode.savingsAccount:
          return savingsAccounts.isNotEmpty ? savingsAccounts.first.id : null;
        case LedgerPaymentMode.cash:
          return cashAccounts.isNotEmpty ? cashAccounts.first.id : null;
        case LedgerPaymentMode.creditCard:
          return cards.isNotEmpty ? cards.first.id : null;
      }
    }();

    _selectedIncomeAccountId ??= savingsAccounts.isNotEmpty
        ? savingsAccounts.first.id
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Add transaction')),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SingleChildScrollView(
          child: AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction type toggle
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Expense'),
                        selected: _isExpense,
                        onSelected: (_) {
                          setState(() => _isExpense = true);
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ChoiceChip(
                        label: const Text('Income'),
                        selected: !_isExpense,
                        onSelected: (_) {
                          setState(() => _isExpense = false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextFormField(
                    controller: _descriptionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Groceries, salary, rent...',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Amount'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an amount';
                      }
                      final parsed = double.tryParse(value);
                      if (parsed == null || parsed <= 0) {
                        return 'Invalid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (_isExpense) ...[
                    _buildExpenseSection(
                      context: context,
                      savingsAccounts: savingsAccounts,
                      cashAccounts: cashAccounts,
                      cards: cards,
                    ),
                  ] else ...[
                    _buildIncomeSection(
                      context: context,
                      savingsAccounts: savingsAccounts,
                      cashAccounts: cashAccounts,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => _onSavePressed(context),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseSection({
    required BuildContext context,
    required List<Account> savingsAccounts,
    required List<Account> cashAccounts,
    required List<CreditCard> cards,
  }) {
    final textTheme = Theme.of(context).textTheme;

    // Determine current list of sources based on selected mode
    final List<dynamic> sources = () {
      switch (_expenseMode) {
        case LedgerPaymentMode.savingsAccount:
          return savingsAccounts;
        case LedgerPaymentMode.cash:
          return cashAccounts;
        case LedgerPaymentMode.creditCard:
          return cards;
      }
    }();

    final hasSources = sources.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Paid with', style: textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            ChoiceChip(
              label: const Text('Savings'),
              selected: _expenseMode == LedgerPaymentMode.savingsAccount,
              onSelected: (_) {
                setState(() {
                  _expenseMode = LedgerPaymentMode.savingsAccount;
                  _selectedExpenseSourceId = savingsAccounts.isNotEmpty
                      ? savingsAccounts.first.id
                      : null;
                });
              },
            ),
            ChoiceChip(
              label: const Text('Cash'),
              selected: _expenseMode == LedgerPaymentMode.cash,
              onSelected: (_) {
                setState(() {
                  _expenseMode = LedgerPaymentMode.cash;
                  _selectedExpenseSourceId = cashAccounts.isNotEmpty
                      ? cashAccounts.first.id
                      : null;
                });
              },
            ),
            ChoiceChip(
              label: const Text('Credit card'),
              selected: _expenseMode == LedgerPaymentMode.creditCard,
              onSelected: (_) {
                setState(() {
                  _expenseMode = LedgerPaymentMode.creditCard;
                  _selectedExpenseSourceId = cards.isNotEmpty
                      ? cards.first.id
                      : null;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        if (!hasSources)
          Text(
            _expenseMode == LedgerPaymentMode.creditCard
                ? 'No cards yet. Add a card first.'
                : 'No accounts yet.',
            style: textTheme.bodySmall?.copyWith(color: Colors.red),
          )
        else
          DropdownButtonFormField<String>(
            value: _selectedExpenseSourceId,
            decoration: const InputDecoration(labelText: 'From'),
            items: [
              for (final s in sources)
                DropdownMenuItem(
                  value: s is Account ? s.id : (s as CreditCard).id,
                  child: Text(
                    s is Account ? s.name : (s as CreditCard).nickname,
                  ),
                ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedExpenseSourceId = value;
              });
            },
          ),
      ],
    );
  }

  Widget _buildIncomeSection({
    required BuildContext context,
    required List<Account> savingsAccounts,
    required List<Account> cashAccounts,
  }) {
    final textTheme = Theme.of(context).textTheme;

    final allAccounts = [...savingsAccounts, ...cashAccounts];
    final hasAccounts = allAccounts.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Received into', style: textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),

        if (!hasAccounts)
          Text(
            'No accounts yet.',
            style: textTheme.bodySmall?.copyWith(color: Colors.red),
          )
        else
          DropdownButtonFormField<String>(
            value: _selectedIncomeAccountId,
            decoration: const InputDecoration(labelText: 'Account'),
            items: [
              for (final a in allAccounts)
                DropdownMenuItem(value: a.id, child: Text(a.name)),
            ],
            onChanged: (value) {
              setState(() {
                _selectedIncomeAccountId = value;
              });
            },
          ),
      ],
    );
  }

  void _onSavePressed(BuildContext context) {
    if (_formKey.currentState?.validate() != true) return;

    final amount = double.parse(_amountCtrl.text.trim());
    final description = _descriptionCtrl.text.trim();

    final ledger = LedgerTransactionStore.instance;
    final accountStore = AccountStore.instance;

    if (_isExpense) {
      if (_selectedExpenseSourceId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a payment source')),
        );
        return;
      }

      ledger.addExpense(
        amount: amount,
        description: description,
        mode: _expenseMode,
        sourceId: _selectedExpenseSourceId!,
      );
    } else {
      // Income
      if (_selectedIncomeAccountId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Select an account')));
        return;
      }

      final account = accountStore.getById(_selectedIncomeAccountId!);
      if (account == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected account not found')),
        );
        return;
      }

      final mode = account.type == AccountType.cash
          ? LedgerPaymentMode.cash
          : LedgerPaymentMode.savingsAccount;

      ledger.addIncome(
        amount: amount,
        description: description,
        accountId: account.id,
        mode: mode,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isExpense ? 'Expense added' : 'Income added')),
    );

    Navigator.of(context).pop();
  }
}
