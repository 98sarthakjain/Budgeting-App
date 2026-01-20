// lib/features/cash/data/hive_cash_account_repository.dart

import 'dart:async';

import 'package:hive/hive.dart';

import 'package:budgeting_app/features/cash/data/cash_account_repository.dart';
import 'package:budgeting_app/features/cash/domain/cash_account.dart';

/// Hive-backed implementation of [CashAccountRepository].
///
/// Stores accounts as plain maps to avoid the boilerplate of Hive adapters.
class HiveCashAccountRepository implements CashAccountRepository {
  static const String _cashAccountId = 'cash-in-hand';

  final Box _box;

  HiveCashAccountRepository(this._box) {
    // Ensure the core cash account exists.
    if (!_box.containsKey(_cashAccountId)) {
      _box.put(
        _cashAccountId,
        _toMap(const CashAccount(id: _cashAccountId, name: 'Cash in hand', balance: 0.0)),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> _toMap(CashAccount a) => {
        'id': a.id,
        'name': a.name,
        'balance': a.balance,
        'isClosed': a.isClosed,
        'closedAt': a.closedAt?.millisecondsSinceEpoch,
      };

  static CashAccount _fromMap(Map m) => CashAccount(
        id: (m['id'] ?? '').toString(),
        name: (m['name'] ?? '').toString(),
        balance: (m['balance'] is num) ? (m['balance'] as num).toDouble() : 0.0,
        isClosed: m['isClosed'] == true,
        closedAt: m['closedAt'] is num
            ? DateTime.fromMillisecondsSinceEpoch((m['closedAt'] as num).toInt())
            : null,
      );

  List<CashAccount> _all({required bool includeClosed}) {
    final all = _box.values
        .whereType<Map>()
        .map(_fromMap)
        .toList(growable: false);

    if (includeClosed) return all;
    return all.where((a) => !a.isClosed).toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // QUERIES
  // ---------------------------------------------------------------------------

  @override
  Future<List<CashAccount>> getAllAccounts({bool includeClosed = false}) async {
    return _all(includeClosed: includeClosed);
  }

  @override
  Stream<List<CashAccount>> watchAllAccounts({bool includeClosed = false}) async* {
    yield _all(includeClosed: includeClosed);
    yield* _box.watch().map((_) => _all(includeClosed: includeClosed));
  }

  @override
  Future<CashAccount?> getById(String id) async {
    final raw = _box.get(id);
    if (raw is! Map) return null;
    return _fromMap(raw);
  }

  @override
  Future<CashAccount> getCashAccount() async {
    final raw = _box.get(_cashAccountId);
    if (raw is Map) return _fromMap(raw);

    // Fallback: recreate if missing
    final cash = const CashAccount(id: _cashAccountId, name: 'Cash in hand', balance: 0.0);
    await _box.put(_cashAccountId, _toMap(cash));
    return cash;
  }

  @override
  Future<List<CashAccount>> getWallets({bool includeClosed = false}) async {
    final wallets = _all(includeClosed: includeClosed)
        .where((a) => a.id != _cashAccountId)
        .toList(growable: false);
    return wallets;
  }

  // ---------------------------------------------------------------------------
  // WALLET CRUD
  // ---------------------------------------------------------------------------

  @override
  Future<CashAccount> createWallet(CashAccount wallet) async {
    await _box.put(wallet.id, _toMap(wallet));
    return wallet;
  }

  @override
  Future<CashAccount> updateWallet(CashAccount wallet) async {
    await _box.put(wallet.id, _toMap(wallet));
    return wallet;
  }

  @override
  Future<void> deleteWallet(String id) async {
    if (id == _cashAccountId) return;
    await _box.delete(id);
  }

  // ---------------------------------------------------------------------------
  // CLOSE / REOPEN
  // ---------------------------------------------------------------------------

  @override
  Future<void> closeWallet(String id, {DateTime? closedAt}) async {
    if (id == _cashAccountId) return;
    final current = await getById(id);
    if (current == null) return;
    final updated = current.copyWith(isClosed: true, closedAt: closedAt ?? DateTime.now());
    await _box.put(id, _toMap(updated));
  }

  @override
  Future<void> reopenWallet(String id) async {
    final current = await getById(id);
    if (current == null) return;
    final updated = current.copyWith(isClosed: false, closedAt: null);
    await _box.put(id, _toMap(updated));
  }

  // ---------------------------------------------------------------------------
  // BALANCE OPS
  // ---------------------------------------------------------------------------

  @override
  Future<void> adjustBalance({required String accountId, required double delta}) async {
    final current = await getById(accountId);
    if (current == null) return;
    final updated = current.copyWith(balance: current.balance + delta);
    await _box.put(accountId, _toMap(updated));
  }

  @override
  Future<void> overrideBalance({required String accountId, required double newBalance}) async {
    final current = await getById(accountId);
    if (current == null) return;
    final updated = current.copyWith(balance: newBalance);
    await _box.put(accountId, _toMap(updated));
  }

  // ---------------------------------------------------------------------------
  // LEGACY COMPAT
  // ---------------------------------------------------------------------------

  /// When using `implements`, Dart does not inherit the default concrete
  /// implementation provided in the abstract class, so we explicitly forward.
  @override
  Future<List<CashAccount>> getAll() => getAllAccounts();
}
