// lib/features/transactions/data/in_memory_transaction_repository.dart

import 'dart:async';

import 'package:budgeting_app/features/transactions/data/transaction_repository.dart';
import 'package:budgeting_app/features/transactions/domain/transaction.dart';

/// Simple in-memory implementation of [TransactionRepository].
///
/// - No persistence; everything is lost on app restart.
/// - Suitable for early development, testing, and UI wiring.
/// - Fully respects the global financial rules documented in
///   lib/docs/global_financial_rules.md.
class InMemoryTransactionRepository implements TransactionRepository {
  final List<Transaction> _txns = <Transaction>[];
  final StreamController<List<Transaction>> _controller =
      StreamController<List<Transaction>>.broadcast();

  InMemoryTransactionRepository();

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  void _emit() {
    // Always emit an immutable snapshot
    _controller.add(List.unmodifiable(_txns));
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();

  DateTime _now() => DateTime.now();

  List<Transaction> _filterByAccountAndDate({
    required String accountId,
    DateTime? from,
    DateTime? to,
  }) {
    return _txns.where((t) {
      if (t.accountId != accountId) return false;

      if (from != null && t.bookingDate.isBefore(from)) {
        return false;
      }
      if (to != null && t.bookingDate.isAfter(to)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<Transaction> _queryInternal({
    List<String>? accountIds,
    List<TransactionType>? types,
    String? categoryId,
    DateTime? from,
    DateTime? to,
    bool? onlyCleared,
    String? textSearch,
  }) {
    return _txns.where((t) {
      if (accountIds != null && accountIds.isNotEmpty) {
        if (!accountIds.contains(t.accountId)) return false;
      }

      if (types != null && types.isNotEmpty) {
        if (!types.contains(t.type)) return false;
      }

      if (categoryId != null && categoryId.isNotEmpty) {
        if (t.categoryId != categoryId) return false;
      }

      if (from != null && t.bookingDate.isBefore(from)) {
        return false;
      }

      if (to != null && t.bookingDate.isAfter(to)) {
        return false;
      }

      if (onlyCleared == true && !t.isCleared) {
        return false;
      }

      if (textSearch != null && textSearch.trim().isNotEmpty) {
        final q = textSearch.toLowerCase();
        final haystack = [
          t.description ?? '',
          t.notes ?? '',
          ...t.tags,
        ].join(' ').toLowerCase();

        if (!haystack.contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  double _computeBalanceFromTxns(
    Iterable<Transaction> txns, {
    DateTime? until,
  }) {
    double balance = 0;

    for (final t in txns) {
      if (until != null && t.bookingDate.isAfter(until)) {
        continue;
      }

      switch (t.type) {
        case TransactionType.income:
        case TransactionType.transferIn:
        case TransactionType.openingBalance:
          balance += t.amount;
          break;

        case TransactionType.expense:
        case TransactionType.transferOut:
          balance -= t.amount;
          break;

        case TransactionType.adjustment:
          if (t.adjustmentDirection == AdjustmentDirection.increase) {
            balance += t.amount;
          } else if (t.adjustmentDirection == AdjustmentDirection.decrease) {
            balance -= t.amount;
          }
          break;
      }
    }

    return balance;
  }

  // ---------------------------------------------------------------------------
  // CREATE
  // ---------------------------------------------------------------------------

  @override
  Future<Transaction> createIncome({
    required String accountId,
    required double amount,
    required DateTime bookingDate,
    String? categoryId,
    String? description,
    String? notes,
    List<String> tags = const [],
  }) async {
    final now = _now();
    final txn = Transaction(
      id: _generateId(),
      accountId: accountId,
      bookingDate: bookingDate,
      createdAt: now,
      updatedAt: now,
      amount: amount,
      type: TransactionType.income,
      categoryId: categoryId,
      description: description,
      notes: notes,
      tags: tags,
    );
    _txns.add(txn);
    _emit();
    return txn;
  }

  @override
  Future<Transaction> createExpense({
    required String accountId,
    required double amount,
    required DateTime bookingDate,
    String? categoryId,
    String? description,
    String? notes,
    List<String> tags = const [],
  }) async {
    final now = _now();
    final txn = Transaction(
      id: _generateId(),
      accountId: accountId,
      bookingDate: bookingDate,
      createdAt: now,
      updatedAt: now,
      amount: amount,
      type: TransactionType.expense,
      categoryId: categoryId,
      description: description,
      notes: notes,
      tags: tags,
    );
    _txns.add(txn);
    _emit();
    return txn;
  }

  @override
  Future<Transaction> createOpeningBalance({
    required String accountId,
    required double amount,
    required DateTime bookingDate,
    String? description,
  }) async {
    final now = _now();
    final txn = Transaction(
      id: _generateId(),
      accountId: accountId,
      bookingDate: bookingDate,
      createdAt: now,
      updatedAt: now,
      amount: amount,
      type: TransactionType.openingBalance,
      description: description ?? 'Opening balance',
    );
    _txns.add(txn);
    _emit();
    return txn;
  }

  @override
  Future<Transaction> createAdjustment({
    required String accountId,
    required double amount,
    required AdjustmentDirection direction,
    required DateTime bookingDate,
    String? description,
    String? notes,
  }) async {
    final now = _now();
    final txn = Transaction(
      id: _generateId(),
      accountId: accountId,
      bookingDate: bookingDate,
      createdAt: now,
      updatedAt: now,
      amount: amount,
      type: TransactionType.adjustment,
      adjustmentDirection: direction,
      description: description ?? 'Balance adjustment',
      notes: notes,
    );
    _txns.add(txn);
    _emit();
    return txn;
  }

  @override
  Future<List<Transaction>> createTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required DateTime bookingDate,
    String? description,
    String? notes,
  }) async {
    final now = _now();
    final transferId = _generateId();

    final outTxn = Transaction(
      id: _generateId(),
      accountId: fromAccountId,
      bookingDate: bookingDate,
      createdAt: now,
      updatedAt: now,
      amount: amount,
      type: TransactionType.transferOut,
      transferGroupId: transferId,
      counterAccountId: toAccountId,
      description: description ?? 'Transfer out',
      notes: notes,
    );

    final inTxn = Transaction(
      id: _generateId(),
      accountId: toAccountId,
      bookingDate: bookingDate,
      createdAt: now,
      updatedAt: now,
      amount: amount,
      type: TransactionType.transferIn,
      transferGroupId: transferId,
      counterAccountId: fromAccountId,
      description: description ?? 'Transfer in',
      notes: notes,
    );

    _txns.add(outTxn);
    _txns.add(inTxn);
    _emit();
    return [outTxn, inTxn];
  }

  // ---------------------------------------------------------------------------
  // UPDATE / DELETE
  // ---------------------------------------------------------------------------

  @override
  Future<Transaction> updateTransaction(Transaction transaction) async {
    final index = _txns.indexWhere((t) => t.id == transaction.id);
    if (index == -1) {
      // Not found; in v1 we can choose to insert or throw. Let's throw.
      throw StateError('Transaction with id ${transaction.id} not found');
    }

    final updated = transaction.copyWith(updatedAt: _now());
    _txns[index] = updated;
    _emit();
    return updated;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _txns.removeWhere((t) => t.id == id);
    _emit();
  }

  // ---------------------------------------------------------------------------
  // READ / QUERY
  // ---------------------------------------------------------------------------

  @override
  Future<Transaction?> getById(String id) async {
    try {
      return _txns.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Transaction>> getByAccount({
    required String accountId,
    DateTime? from,
    DateTime? to,
  }) async {
    return _filterByAccountAndDate(accountId: accountId, from: from, to: to);
  }

  @override
  Stream<List<Transaction>> watchByAccount({
    required String accountId,
    DateTime? from,
    DateTime? to,
  }) {
    // Start from current snapshot, then emit updates.
    final initial = _filterByAccountAndDate(
      accountId: accountId,
      from: from,
      to: to,
    );

    // Emit initial snapshot to the listener.
    final controller = StreamController<List<Transaction>>();

    void emitFiltered(List<Transaction> all) {
      controller.add(
        all.where((t) {
          if (t.accountId != accountId) return false;

          if (from != null && t.bookingDate.isBefore(from)) return false;
          if (to != null && t.bookingDate.isAfter(to)) return false;

          return true;
        }).toList(),
      );
    }

    // Push initial
    controller.add(initial);

    final sub = _controller.stream.listen(emitFiltered);

    controller.onCancel = () {
      sub.cancel();
    };

    return controller.stream;
  }

  @override
  Future<List<Transaction>> query({
    List<String>? accountIds,
    List<TransactionType>? types,
    String? categoryId,
    DateTime? from,
    DateTime? to,
    bool? onlyCleared,
    String? textSearch,
  }) async {
    return _queryInternal(
      accountIds: accountIds,
      types: types,
      categoryId: categoryId,
      from: from,
      to: to,
      onlyCleared: onlyCleared,
      textSearch: textSearch,
    );
  }

  /// Lightweight helper to check if ANY transactions exist for an account.
  ///
  /// Used by account modules (Savings, Cash, Cards, Loans, etc.) to decide
  /// whether an account can be hard deleted, or must be closed instead.
  @override
  Future<bool> hasAnyForAccount(String accountId) async {
    return _txns.any((t) => t.accountId == accountId);
  }

  // ---------------------------------------------------------------------------
  // BALANCE HELPERS
  // ---------------------------------------------------------------------------

  @override
  Future<double> computeBalance({
    required String accountId,
    DateTime? until,
  }) async {
    final txns = _txns.where((t) => t.accountId == accountId);
    return _computeBalanceFromTxns(txns, until: until);
  }

  @override
  Future<IncomeExpenseSummary> computeIncomeExpenseSummary({
    List<String>? accountIds,
    DateTime? from,
    DateTime? to,
  }) async {
    final txns = _queryInternal(
      accountIds: accountIds,
      from: from,
      to: to,
      // We intentionally do NOT filter by type here;
      // we'll filter manually to enforce rules.
    );

    double income = 0;
    double expense = 0;

    for (final t in txns) {
      switch (t.type) {
        case TransactionType.income:
          income += t.amount;
          break;
        case TransactionType.expense:
          expense += t.amount;
          break;

        case TransactionType.transferIn:
        case TransactionType.transferOut:
        case TransactionType.openingBalance:
        case TransactionType.adjustment:
          // Explicitly excluded from income/expense summary.
          break;
      }
    }

    return IncomeExpenseSummary(totalIncome: income, totalExpense: expense);
  }
}
