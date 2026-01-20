// lib/features/transactions/domain/ledger_entry.dart
import 'package:flutter/foundation.dart';

enum LedgerEntryType { expense, income, transfer }

enum LedgerPaymentMode { savingsAccount, creditCard, cash }

@immutable
class LedgerEntry {
  final String id;
  final LedgerEntryType type;
  final double amount;
  final String description;
  final DateTime timestamp;

  // For expense/income
  final LedgerPaymentMode? mode;
  final String? sourceId; // accountId or cardId

  // For transfers (e.g., paying credit card bill)
  final String? fromAccountId;
  final String? toCreditCardId;

  const LedgerEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
    this.mode,
    this.sourceId,
    this.fromAccountId,
    this.toCreditCardId,
  });
}
