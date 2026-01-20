// lib/features/cards/presentation/add_card_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:budgeting_app/core/widgets/app_card.dart';
import 'package:budgeting_app/core/design/spacing.dart';
import 'package:budgeting_app/features/cards/data/card_repository.dart';
import 'package:budgeting_app/features/cards/domain/credit_card.dart';
import 'package:budgeting_app/features/transactions/data/transaction_repository.dart';

class AddCardScreen extends StatefulWidget {
  final CardRepository repository;
  final TransactionRepository transactionRepository; // reserved for future flows

  const AddCardScreen({
    super.key,
    required this.repository,
    required this.transactionRepository,
  });

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  static const List<String> _knownBanks = [
    'HDFC Bank',
    'ICICI Bank',
    'Axis Bank',
    'SBI',
    'Kotak Mahindra Bank',
    'IndusInd Bank',
    'Yes Bank',
    'IDFC FIRST Bank',
    'Federal Bank',
    'RBL Bank',
    'HSBC',
    'Standard Chartered',
    'AU Small Finance Bank',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();

  final _nicknameCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _last4Ctrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  final _billingDayCtrl = TextEditingController(text: '10');
  final _dueDayCtrl = TextEditingController(text: '20');
  final _annualFeeCtrl = TextEditingController(text: '0');
  final _cashbackCtrl = TextEditingController();

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _holderCtrl.dispose();
    _bankCtrl.dispose();
    _last4Ctrl.dispose();
    _limitCtrl.dispose();
    _billingDayCtrl.dispose();
    _dueDayCtrl.dispose();
    _annualFeeCtrl.dispose();
    _cashbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;

    final last4 = _last4Ctrl.text.trim();

    final faces = <CardFace>[];
    if (last4.isNotEmpty) {
      // Store the last-4 as the primary face so we can disambiguate cards later.
      faces.add(CardFace(id: 'primary', scheme: 'Card', last4: last4));
    }

    final card = CreditCard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nickname: _nicknameCtrl.text.trim(),
      holderName: _holderCtrl.text.trim().isEmpty
          ? _nicknameCtrl.text.trim()
          : _holderCtrl.text.trim(),
      bankName: _bankCtrl.text.trim(),
      creditLimit: double.parse(_limitCtrl.text.trim()),
      billingDay: int.parse(_billingDayCtrl.text.trim()),
      dueDay: int.parse(_dueDayCtrl.text.trim()),
      annualFee: _annualFeeCtrl.text.trim().isEmpty
          ? 0.0
          : double.parse(_annualFeeCtrl.text.trim()),
      cashbackSummary: _cashbackCtrl.text.trim(),
      faces: faces,
    );

    await widget.repository.upsertCard(card);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Card "${card.nickname}" added')));

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Add card')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SingleChildScrollView(
          child: AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nicknameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Card nickname',
                      hintText: 'Amazon ICICI, HDFC Millennia...',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a nickname';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _holderCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Card holder name',
                      hintText: 'Name printed on card',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: _knownBanks.contains(_bankCtrl.text) ? _bankCtrl.text : null,
                    items: _knownBanks
                        .map((b) => DropdownMenuItem<String>(value: b, child: Text(b)))
                        .toList(growable: false),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _bankCtrl.text = v;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Bank',
                    ),
                    validator: (_) {
                      if (_bankCtrl.text.trim().isEmpty) {
                        return 'Please select a bank';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _last4Ctrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 4,
                    decoration: const InputDecoration(
                      labelText: 'Card number (last 4)',
                      hintText: '1234',
                      counterText: '',
                    ),
                    validator: (value) {
                      final v = (value ?? '').trim();
                      if (v.isEmpty) return null; // optional
                      if (v.length != 4) return 'Enter 4 digits';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _limitCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Credit limit',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a limit';
                      }
                      final parsed = double.tryParse(value);
                      if (parsed == null || parsed <= 0) {
                        return 'Invalid limit';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _billingDayCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Billing day',
                            helperText: '1–31',
                          ),
                          validator: (value) {
                            final parsed = int.tryParse(value?.trim() ?? '');
                            if (parsed == null || parsed < 1 || parsed > 31) {
                              return '1–31';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _dueDayCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Due day',
                            helperText: '1–31',
                          ),
                          validator: (value) {
                            final parsed = int.tryParse(value?.trim() ?? '');
                            if (parsed == null || parsed < 1 || parsed > 31) {
                              return '1–31';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _annualFeeCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Annual fee',
                      helperText: '0 if lifetime free',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return null; // treat as 0
                      }
                      final parsed = double.tryParse(value);
                      if (parsed == null || parsed < 0) {
                        return 'Invalid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _cashbackCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cashback summary',
                      hintText: '5% Amazon, 1.5% others, ₹1500/qtr cap',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _save,
                      child: Text('Save', style: textTheme.labelLarge),
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
}
