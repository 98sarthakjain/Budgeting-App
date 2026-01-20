// lib/features/savings/presentation/add_edit_savings_account_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:budgeting_app/core/design/spacing.dart';
import 'package:budgeting_app/core/widgets/app_card.dart';
import 'package:budgeting_app/features/savings/data/savings_account_repository.dart';
import 'package:budgeting_app/features/savings/domain/savings_account.dart';
import 'package:budgeting_app/features/transactions/data/transaction_repository.dart';
import 'package:budgeting_app/features/transactions/domain/transaction.dart';

class AddEditSavingsAccountScreen extends StatefulWidget {
  final SavingsAccountRepository repository;
  final TransactionRepository transactionRepository;
  final SavingsAccount? initialAccount;

  const AddEditSavingsAccountScreen({
    super.key,
    required this.repository,
    required this.transactionRepository,
    this.initialAccount,
  });

  bool get isEditMode => initialAccount != null;

  @override
  State<AddEditSavingsAccountScreen> createState() =>
      _AddEditSavingsAccountScreenState();
}

class _AddEditSavingsAccountScreenState
    extends State<AddEditSavingsAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  String? _selectedBankName;
  final TextEditingController _accountNicknameController =
      TextEditingController();
  String? _selectedAccountType;
  bool _isSalaryAccount = false;
  final TextEditingController _maskedAccountNumberController =
      TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _currentBalanceController =
      TextEditingController();

  bool _isSaving = false;

  // Static bank list – can be moved to a shared const later
  static const List<String> _knownBanks = [
    'HDFC Bank',
    'ICICI Bank',
    'State Bank of India',
    'Axis Bank',
    'Kotak Mahindra Bank',
    'Yes Bank',
    'IDFC FIRST Bank',
    'IndusInd Bank',
    'Bank of Baroda',
    'Punjab National Bank',
    'Union Bank of India',
    'Canara Bank',
    'IDBI Bank',
    'Federal Bank',
    'RBL Bank',
  ];

  static const List<String> _accountTypes = [
    'Savings',
    'NRE',
    'NRO',
    'Joint',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initFromExisting();
  }

  void _initFromExisting() {
    final existing = widget.initialAccount;
    if (existing == null) {
      // Defaults for add mode
      _selectedAccountType = 'Savings';
      _isSalaryAccount = false;
      return;
    }

    _selectedBankName = existing.bankName;
    _accountNicknameController.text = existing.accountNickname;
    _selectedAccountType = existing.accountType;
    _isSalaryAccount = existing.isSalaryAccount;
    _maskedAccountNumberController.text = existing.maskedAccountNumber;
    _ifscController.text = existing.ifsc;
    _currentBalanceController.text = existing.currentBalance.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _accountNicknameController.dispose();
    _maskedAccountNumberController.dispose();
    _ifscController.dispose();
    _currentBalanceController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now();
      final parsedBalance =
          double.tryParse(
            _currentBalanceController.text.replaceAll(',', '').trim(),
          ) ??
          0.0;

      final existing = widget.initialAccount;

      final account = SavingsAccount(
        id: existing?.id ?? _generateAccountId(),
        bankName: _selectedBankName!,
        accountNickname: _accountNicknameController.text.trim(),
        accountType: _selectedAccountType ?? 'Savings',
        maskedAccountNumber: _maskedAccountNumberController.text.trim(),
        ifsc: _ifscController.text.trim(),
        branchName: existing?.branchName ?? '',
        // NOTE: These are now informational; true balance comes from ledger.
        currentBalance: parsedBalance,
        availableBalance: parsedBalance,
        interestRate: existing?.interestRate ?? 0.0,
        minBalanceRequired: existing?.minBalanceRequired ?? 0.0,
        isSalaryAccount: _isSalaryAccount,
        hasNominee: existing?.hasNominee ?? false,
        lastInterestCreditedOn: existing?.lastInterestCreditedOn ?? now,
        lastInterestAmount: existing?.lastInterestAmount ?? 0.0,
        isClosed: existing?.isClosed ?? false,
        closedAt: existing?.closedAt,
      );

      if (widget.isEditMode) {
        // 1) Update account metadata
        await widget.repository.updateAccount(account);

        // 2) Reconcile balance via adjustment transaction (if needed)
        final ledgerBalance = await widget.transactionRepository.computeBalance(
          accountId: account.id,
        );

        final delta = parsedBalance - ledgerBalance;
        const epsilon = 0.01; // ignore tiny floating differences

        if (delta.abs() > epsilon) {
          await widget.transactionRepository.createAdjustment(
            accountId: account.id,
            amount: delta.abs(),
            direction: delta > 0
                ? AdjustmentDirection.increase
                : AdjustmentDirection.decrease,
            bookingDate: now,
            description: 'Manual balance adjustment',
          );
        }
      } else {
        // ADD mode
        // 1) Create account metadata
        await widget.repository.createAccount(account);

        // 2) Create opening balance transaction (if > 0)
        if (parsedBalance > 0) {
          await widget.transactionRepository.createOpeningBalance(
            accountId: account.id,
            amount: parsedBalance,
            bookingDate: now,
            description: 'Opening balance',
          );
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _handleDelete() async {
    if (!widget.isEditMode || widget.initialAccount == null) return;

    final accountId = widget.initialAccount!.id;

    // 1) Check if there are ANY transactions for this account.
    final txns = await widget.transactionRepository.getByAccount(
      accountId: accountId,
    );

    if (!mounted) return;

    // -----------------------------------------------------------------
    // CASE A — No transactions: allow hard delete
    // -----------------------------------------------------------------
    if (txns.isEmpty) {
      final confirmDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete account'),
          content: const Text(
            'This account has no transaction history.\n\n'
            'You can safely delete it. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmDelete == true) {
        await widget.repository.deleteAccount(accountId);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      }
      return;
    }

    // -----------------------------------------------------------------
    // CASE B — Has transactions: prefer closing, but only if balance == 0
    // -----------------------------------------------------------------
    final ledgerBalance = await widget.transactionRepository.computeBalance(
      accountId: accountId,
    );

    if (!mounted) return;
    const epsilon = 0.01;

    if (ledgerBalance.abs() > epsilon) {
      // Non-zero balance → cannot close, must reconcile first.
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot close account'),
          content: Text(
            'This account has transaction history and a non-zero balance '
            '(${ledgerBalance.toStringAsFixed(2)}).\n\n'
            'To close it, first bring the balance to 0 using transfers or an '
            'adjustment transaction, then try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Balance is zero → offer to close the account.
    final confirmClose = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close account'),
        content: const Text(
          'This account has transaction history but a zero balance.\n\n'
          'You cannot delete it, but you can close it:\n'
          '• It will be hidden from active lists.\n'
          '• Past transactions and reports will remain accurate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Close account'),
          ),
        ],
      ),
    );

    if (confirmClose == true) {
      await widget.repository.closeAccount(accountId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }
  }

  String _generateAccountId() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    return 'savings-$millis';
  }

  Future<void> _showBankPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _BankPickerSheet(
          banks: _knownBanks,
          initialSelection: _selectedBankName,
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedBankName = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEditMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit savings account' : 'Add savings account'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bank details card
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Bank details',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Bank name (picker)
                        GestureDetector(
                          onTap: _showBankPicker,
                          child: AbsorbPointer(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Bank name',
                                hintText: 'e.g. HDFC Bank',
                              ),
                              controller: TextEditingController(
                                text: _selectedBankName ?? '',
                              ),
                              validator: (_) {
                                if (_selectedBankName == null ||
                                    _selectedBankName!.trim().isEmpty) {
                                  return 'Please select a bank';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Account nickname
                        TextFormField(
                          controller: _accountNicknameController,
                          decoration: const InputDecoration(
                            labelText: 'Account nickname',
                            hintText: 'e.g. Salary account, Main savings',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an account nickname';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Account type
                        DropdownButtonFormField<String>(
                          initialValue: _selectedAccountType,
                          items: _accountTypes
                              .map(
                                (type) => DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedAccountType = value;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Account type',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please select an account type';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Salary account toggle
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('This is a salary account'),
                          subtitle: const Text(
                            'Zero-balance allowed if this is your salary account.',
                          ),
                          value: _isSalaryAccount,
                          onChanged: (value) {
                            setState(() {
                              _isSalaryAccount = value;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Masked account number
                        TextFormField(
                          controller: _maskedAccountNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Displayed account number',
                            hintText: 'XXXX 1234',
                            helperText:
                                'For your reference only. Full number is never stored.',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // IFSC (optional)
                        TextFormField(
                          controller: _ifscController,
                          decoration: const InputDecoration(
                            labelText: 'IFSC (optional)',
                            hintText: 'e.g. HDFC0000456',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Balance card
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Balance',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        TextFormField(
                          controller: _currentBalanceController,
                          decoration: const InputDecoration(
                            labelText: 'Current balance',
                            hintText: 'e.g. 25,000',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the current balance';
                            }
                            final parsed = double.tryParse(
                              value.replaceAll(',', '').trim(),
                            );
                            if (parsed == null || parsed < 0) {
                              return 'Enter a valid non-negative amount';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Primary action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEdit ? 'Save changes' : 'Save account'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Delete / Close button (edit mode only)
                if (widget.isEditMode)
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _handleDelete,
                      child: const Text('Delete account'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BankPickerSheet extends StatefulWidget {
  final List<String> banks;
  final String? initialSelection;

  const _BankPickerSheet({Key? key, required this.banks, this.initialSelection})
    : super(key: key);

  @override
  State<_BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<_BankPickerSheet> {
  late List<String> _filteredBanks;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredBanks = List<String>.from(widget.banks);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredBanks = List<String>.from(widget.banks);
      } else {
        _filteredBanks = widget.banks
            .where((b) => b.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select bank',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search bank',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _filteredBanks.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final bank = _filteredBanks[index];
                  final isSelected = bank == widget.initialSelection;
                  return ListTile(
                    title: Text(bank),
                    trailing: isSelected
                        ? const Icon(Icons.check, size: 20)
                        : null,
                    onTap: () => Navigator.of(context).pop(bank),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
