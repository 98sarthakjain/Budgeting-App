// lib/features/cash/presentation/add_edit_wallet_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:budgeting_app/core/design/spacing.dart';
import 'package:budgeting_app/core/widgets/app_card.dart';
import 'package:budgeting_app/features/cash/data/cash_account_repository.dart';
import 'package:budgeting_app/features/cash/domain/cash_account.dart';
import 'package:budgeting_app/features/transactions/data/transaction_repository.dart';
import 'package:budgeting_app/features/transactions/domain/transaction.dart';

class AddEditWalletScreen extends StatefulWidget {
  final CashAccountRepository repository;
  final TransactionRepository transactionRepository;
  final CashAccount? initialWallet;

  const AddEditWalletScreen({
    super.key,
    required this.repository,
    required this.transactionRepository,
    this.initialWallet,
  });

  bool get isEditMode => initialWallet != null;

  @override
  State<AddEditWalletScreen> createState() => _AddEditWalletScreenState();
}

class _AddEditWalletScreenState extends State<AddEditWalletScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _walletNameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();

  bool _isSaving = false;
  bool _isBusyAction = false; // for close/delete

  @override
  void initState() {
    super.initState();
    _initFromExisting();
  }

  void _initFromExisting() {
    final existing = widget.initialWallet;
    if (existing == null) return;

    _walletNameController.text = existing.name;
    _balanceController.text = existing.balance.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _walletNameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving || _isBusyAction) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final name = _walletNameController.text.trim();
      final parsedBalance =
          double.tryParse(_balanceController.text.replaceAll(',', '').trim()) ??
          0.0;

      final existing = widget.initialWallet;
      final now = DateTime.now();

      if (existing == null) {
        // ADD mode
        final wallet = CashAccount(
          id: _generateWalletId(),
          name: name,
          balance: parsedBalance, // informational; true balance from ledger
        );
        await widget.repository.createWallet(wallet);

        if (parsedBalance > 0) {
          await widget.transactionRepository.createOpeningBalance(
            accountId: wallet.id,
            amount: parsedBalance,
            bookingDate: now,
            description: 'Opening balance (wallet)',
          );
        }
      } else {
        // EDIT mode
        final updated = existing.copyWith(name: name, balance: parsedBalance);
        await widget.repository.updateWallet(updated);

        final ledgerBalance = await widget.transactionRepository.computeBalance(
          accountId: existing.id,
        );

        final delta = parsedBalance - ledgerBalance;
        const epsilon = 0.01;

        if (delta.abs() > epsilon) {
          await widget.transactionRepository.createAdjustment(
            accountId: existing.id,
            amount: delta.abs(),
            direction: delta > 0
                ? AdjustmentDirection.increase
                : AdjustmentDirection.decrease,
            bookingDate: now,
            description: 'Manual wallet balance adjustment',
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

  Future<void> _handleCloseOrDelete() async {
    if (!widget.isEditMode || _isSaving || _isBusyAction) return;

    final wallet = widget.initialWallet!;
    setState(() {
      _isBusyAction = true;
    });

    try {
      // Check if wallet has any transactions in the ledger
      final txns = await widget.transactionRepository.getByAccount(
        accountId: wallet.id,
      );

      if (!mounted) return;

      if (txns.isEmpty) {
        // Wallet has no history → user can either close or hard-delete
        final result = await showDialog<_WalletAction>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove wallet'),
            content: const Text(
              'This wallet has no transactions.\n\n'
              'You can either delete it permanently, or close it and keep it '
              'hidden from active views.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(_WalletAction.cancel),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(_WalletAction.closeOnly),
                child: const Text('Close wallet'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(_WalletAction.deletePermanently),
                child: const Text('Delete permanently'),
              ),
            ],
          ),
        );

        if (!mounted || result == null || result == _WalletAction.cancel) {
          return;
        }

        if (result == _WalletAction.deletePermanently) {
          await widget.repository.deleteWallet(wallet.id);
        } else if (result == _WalletAction.closeOnly) {
          await widget.repository.closeWallet(wallet.id);
        }
      } else {
        // Wallet has history → only allow closing
        final confirmClose = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Close wallet'),
            content: const Text(
              'This wallet has existing transactions.\n\n'
              'To keep your history and balances consistent, it cannot be '
              'deleted. You can close it so it stops appearing in active '
              'screens, but all past transactions will remain.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Close wallet'),
              ),
            ],
          ),
        );

        if (confirmClose == true) {
          await widget.repository.closeWallet(wallet.id);
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() {
          _isBusyAction = false;
        });
      }
    }
  }

  String _generateWalletId() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    return 'wallet-$millis';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEdit = widget.isEditMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit wallet' : 'Add wallet',
          style: textTheme.titleLarge,
        ),
        centerTitle: true,
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
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Wallet details',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Wallet name / nickname
                        TextFormField(
                          controller: _walletNameController,
                          decoration: const InputDecoration(
                            labelText: 'Wallet name',
                            hintText: 'e.g. Paytm personal, PhonePe rent',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a wallet name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Current balance
                        TextFormField(
                          controller: _balanceController,
                          decoration: const InputDecoration(
                            labelText: 'Current balance',
                            hintText: 'e.g. 1,500',
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

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving || _isBusyAction ? null : _handleSave,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEdit ? 'Save changes' : 'Save wallet'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                if (widget.isEditMode)
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isSaving || _isBusyAction
                          ? null
                          : _handleCloseOrDelete,
                      child: const Text('Close / delete wallet'),
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

enum _WalletAction { cancel, closeOnly, deletePermanently }
