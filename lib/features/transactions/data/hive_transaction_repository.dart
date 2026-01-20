// lib/features/transactions/data/hive_transaction_repository.dart

import 'dart:async';

import 'package:hive/hive.dart';

import 'package:budgeting_app/features/transactions/data/transaction_repository.dart';
import 'package:budgeting_app/features/transactions/domain/transaction.dart';

/// Hive-backed implementation of [TransactionRepository].
///
/// Stores transactions as plain maps in Hive. This avoids the need for Hive
/// TypeAdapters and keeps migrations simpler while the schema is still
/// evolving.
class HiveTransactionRepository implements TransactionRepository {
  final Box _box;

  HiveTransactionRepository(this._box);

  // ---------------------------------------------------------------------------
  // Watch
  // ---------------------------------------------------------------------------

  @override
  Stream<void> watchAll() async* {
    // immediate tick
    yield null;
    await for (final _ in _box.watch()) {
      yield null;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();

  DateTime _now() => DateTime.now();

  static int _dtToInt(DateTime dt) => dt.millisecondsSinceEpoch;

  static DateTime _intToDt(Object? v) {
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    return DateTime.now();
  }

  static Map<String, dynamic> _toMap(Transaction t) => {
        'id': t.id,
        'accountId': t.accountId,
        'bookingDate': _dtToInt(t.bookingDate),
        'createdAt': _dtToInt(t.createdAt),
        'updatedAt': _dtToInt(t.updatedAt),
        'amount': t.amount,
        'type': t.type.index,
        'adjustmentDirection': t.adjustmentDirection?.index,
        'transferGroupId': t.transferGroupId,
        'counterAccountId': t.counterAccountId,
        'categoryId': t.categoryId,
        'description': t.description,
        'notes': t.notes,
        'tags': t.tags,
        'isCleared': t.isCleared,
      };

  static Transaction _fromMap(Map m) {
    final typeIdx = m['type'];
    final dirIdx = m['adjustmentDirection'];
    final tagsRaw = m['tags'];
    final tags = tagsRaw is List
        ? tagsRaw.map((e) => e.toString()).toList(growable: false)
        : const <String>[];

    return Transaction(
      id: (m['id'] ?? '').toString(),
      accountId: (m['accountId'] ?? '').toString(),
      bookingDate: _intToDt(m['bookingDate']),
      createdAt: _intToDt(m['createdAt']),
      updatedAt: _intToDt(m['updatedAt']),
      amount: (m['amount'] is num) ? (m['amount'] as num).toDouble() : 0.0,
      type: (typeIdx is num)
          ? TransactionType.values[typeIdx.toInt()]
          : TransactionType.expense,
      adjustmentDirection: (dirIdx is num)
          ? AdjustmentDirection.values[dirIdx.toInt()]
          : null,
      transferGroupId: m['transferGroupId']?.toString(),
      counterAccountId: m['counterAccountId']?.toString(),
      categoryId: m['categoryId']?.toString(),
      description: m['description']?.toString(),
      notes: m['notes']?.toString(),
      tags: tags,
      isCleared: m['isCleared'] != false,
    );
  }

  List<Transaction> _allTxns() {
    return _box.values
        .whereType<Map>()
        .map(_fromMap)
        .toList(growable: false);
  }

  List<Transaction> _filterByAccountAndDate({
    required String accountId,
    DateTime? from,
    DateTime? to,
  }) {
    final all = _allTxns();
    return all.where((t) {
      if (t.accountId != accountId) return false;

      if (from != null && t.bookingDate.isBefore(from)) return false;
      if (to != null && t.bookingDate.isAfter(to)) return false;

      return true;
    }).toList(growable: false);
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
    final all = _allTxns();
    return all.where((t) {
      if (accountIds != null && accountIds.isNotEmpty) {
        if (!accountIds.contains(t.accountId)) return false;
      }

      if (types != null && types.isNotEmpty) {
        if (!types.contains(t.type)) return false;
      }

      if (categoryId != null && categoryId.isNotEmpty) {
        if (t.categoryId != categoryId) return false;
      }

      if (from != null && t.bookingDate.isBefore(from)) return false;
      if (to != null && t.bookingDate.isAfter(to)) return false;

      if (onlyCleared == true && !t.isCleared) return false;

      if (textSearch != null && textSearch.trim().isNotEmpty) {
        final q = textSearch.toLowerCase();
        final haystack = [
          t.description ?? '',
          t.notes ?? '',
          ...t.tags,
        ].join(' ').toLowerCase();
        if (!haystack.contains(q)) return false;
      }

      return true;
    }).toList(growable: false);
  }

  double _computeBalanceFromTxns(Iterable<Transaction> txns, {DateTime? until}) {
    double balance = 0;

    for (final t in txns) {
      if (until != null && t.bookingDate.isAfter(until)) continue;

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
    await _box.put(txn.id, _toMap(txn));
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
    await _box.put(txn.id, _toMap(txn));
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
    await _box.put(txn.id, _toMap(txn));
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
    await _box.put(txn.id, _toMap(txn));
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

    await _box.put(outTxn.id, _toMap(outTxn));
    await _box.put(inTxn.id, _toMap(inTxn));

    return [outTxn, inTxn];
  }

  // ---------------------------------------------------------------------------
  // UPDATE / DELETE
  // ---------------------------------------------------------------------------

  @override
  Future<Transaction> updateTransaction(Transaction transaction) async {
    if (!_box.containsKey(transaction.id)) {
      throw StateError('Transaction with id ${transaction.id} not found');
    }
    final updated = transaction.copyWith(updatedAt: _now());
    await _box.put(updated.id, _toMap(updated));
    return updated;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _box.delete(id);
  }

  // ---------------------------------------------------------------------------
  // READ / QUERY
  // ---------------------------------------------------------------------------

  @override
  Future<Transaction?> getById(String id) async {
    final raw = _box.get(id);
    if (raw is! Map) return null;
    return _fromMap(raw);
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
  }) async* {
    yield _filterByAccountAndDate(accountId: accountId, from: from, to: to);
    yield* _box.watch().map(
          (_) => _filterByAccountAndDate(
            accountId: accountId,
            from: from,
            to: to,
          ),
        );
  }

  @override
  Future<bool> hasAnyForAccount(String accountId) async {
    return _allTxns().any((t) => t.accountId == accountId);
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

  // ---------------------------------------------------------------------------
  // BALANCE HELPERS
  // ---------------------------------------------------------------------------

  @override
  Future<double> computeBalance({required String accountId, DateTime? until}) async {
    final txns = _allTxns().where((t) => t.accountId == accountId);
    return _computeBalanceFromTxns(txns, until: until);
  }

  @override
  Future<IncomeExpenseSummary> computeIncomeExpenseSummary({
    List<String>? accountIds,
    DateTime? from,
    DateTime? to,
  }) async {
    final txns = _queryInternal(accountIds: accountIds, from: from, to: to);

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
          break;
      }
    }

    return IncomeExpenseSummary(totalIncome: income, totalExpense: expense);
  }
}
