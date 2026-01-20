import 'package:flutter/foundation.dart';
import 'package:budgeting_app/features/transactions/domain/ledger_entry.dart';
import 'package:budgeting_app/core/services/account_store.dart';
import 'package:budgeting_app/core/services/card_store.dart';

/// In-memory ledger for high-level financial logic.
/// This is separate from your old Hive `Transaction` model.
class LedgerTransactionStore extends ChangeNotifier {
  LedgerTransactionStore._internal();
  static final LedgerTransactionStore instance =
      LedgerTransactionStore._internal();

  final List<LedgerEntry> _entries = [];

  List<LedgerEntry> get entries => List.unmodifiable(_entries);

  // --------- Public API ----------------------------------------

  /// Add an expense paid by savings account / credit card / cash.
  LedgerEntry addExpense({
    required double amount,
    required String description,
    required LedgerPaymentMode mode,
    required String sourceId, // accountId or cardId depending on mode
    DateTime? timestamp,
  }) {
    final entry = LedgerEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: LedgerEntryType.expense,
      amount: amount,
      description: description,
      timestamp: timestamp ?? DateTime.now(),
      mode: mode,
      sourceId: sourceId,
    );

    _entries.add(entry);

    // Side-effects on accounts / cards
    switch (mode) {
      case LedgerPaymentMode.savingsAccount:
        AccountStore.instance.applyBalanceDelta(sourceId, -amount);
        break;
      case LedgerPaymentMode.cash:
        AccountStore.instance.applyBalanceDelta(sourceId, -amount);
        break;
      case LedgerPaymentMode.creditCard:
        CardStore.instance.applyOutstandingDelta(sourceId, amount);
        break;
    }

    notifyListeners();
    return entry;
  }

  /// Add income into a savings or cash account.
  LedgerEntry addIncome({
    required double amount,
    required String description,
    required String accountId,
    required LedgerPaymentMode mode, // must be savingsAccount or cash
    DateTime? timestamp,
  }) {
    final entry = LedgerEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: LedgerEntryType.income,
      amount: amount,
      description: description,
      timestamp: timestamp ?? DateTime.now(),
      mode: mode,
      sourceId: accountId,
    );

    _entries.add(entry);

    // Income always increases the target account
    AccountStore.instance.applyBalanceDelta(accountId, amount);

    notifyListeners();
    return entry;
  }

  /// Pay a credit card bill from a savings account.
  /// This is a TRANSFER, not an expense (so no double counting).
  LedgerEntry payCreditCardBill({
    required double amount,
    required String fromSavingsAccountId,
    required String cardId,
    String description = 'Credit card payment',
    DateTime? timestamp,
  }) {
    final entry = LedgerEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: LedgerEntryType.transfer,
      amount: amount,
      description: description,
      timestamp: timestamp ?? DateTime.now(),
      fromAccountId: fromSavingsAccountId,
      toCreditCardId: cardId,
    );

    _entries.add(entry);

    // Move money: savings --, outstanding --
    AccountStore.instance.applyBalanceDelta(fromSavingsAccountId, -amount);
    CardStore.instance.applyOutstandingDelta(cardId, -amount);

    notifyListeners();
    return entry;
  }

  // --------- Summary helpers -----------------------------------

  double get totalExpenses => _entries
      .where((e) => e.type == LedgerEntryType.expense)
      .fold(0.0, (sum, e) => sum + e.amount);

  double get totalIncome => _entries
      .where((e) => e.type == LedgerEntryType.income)
      .fold(0.0, (sum, e) => sum + e.amount);

  /// Net position just from ledger entries (income - expenses).
  double get netFlow => totalIncome - totalExpenses;
}
