// lib/features/cash/data/in_memory_cash_account_repository.dart

import 'dart:async';

import 'package:budgeting_app/features/cash/data/cash_account_repository.dart';
import 'package:budgeting_app/features/cash/domain/cash_account.dart';

class InMemoryCashAccountRepository implements CashAccountRepository {
  static const String _cashAccountId = 'cash-in-hand';

  final List<CashAccount> _accounts;
  final StreamController<List<CashAccount>> _controller =
      StreamController<List<CashAccount>>.broadcast();

  InMemoryCashAccountRepository({List<CashAccount>? seed})
    : _accounts = seed ?? _defaultAccounts {
    // Ensure there is always a "Cash in hand" account
    if (_accounts.indexWhere((a) => a.id == _cashAccountId) == -1) {
      _accounts.insert(
        0,
        const CashAccount(
          id: _cashAccountId,
          name: 'Cash in hand',
          balance: 0.0,
        ),
      );
    }
    _emit();
  }

  void _emit() {
    _controller.add(List.unmodifiable(_accounts));
  }

  int _indexOf(String id) =>
      _accounts.indexWhere((account) => account.id == id);

  // ------------------------------------------------------------
  // QUERIES
  // ------------------------------------------------------------

  @override
  Future<List<CashAccount>> getAllAccounts({bool includeClosed = false}) async {
    if (includeClosed) {
      return List.unmodifiable(_accounts);
    }
    return List.unmodifiable(_accounts.where((a) => !a.isClosed));
  }

  /// Legacy compat for older code calling getAll().
  @override
  Future<List<CashAccount>> getAll() => getAllAccounts();

  @override
  Stream<List<CashAccount>> watchAllAccounts({bool includeClosed = false}) {
    // Map underlying stream into filtered view for each listener.
    final controller = StreamController<List<CashAccount>>();

    void emitFiltered(List<CashAccount> all) {
      final filtered = includeClosed
          ? all
          : all.where((a) => !a.isClosed).toList(growable: false);
      controller.add(List.unmodifiable(filtered));
    }

    // Push current snapshot
    emitFiltered(_accounts);

    final sub = _controller.stream.listen(emitFiltered);
    controller.onCancel = () => sub.cancel();

    return controller.stream;
  }

  @override
  Future<CashAccount?> getById(String id) async {
    final index = _indexOf(id);
    if (index == -1) return null;
    return _accounts[index];
  }

  @override
  Future<CashAccount> getCashAccount() async {
    final index = _indexOf(_cashAccountId);
    if (index != -1) return _accounts[index];

    // Fallback: create if somehow missing
    final cash = const CashAccount(
      id: _cashAccountId,
      name: 'Cash in hand',
      balance: 0.0,
    );
    _accounts.insert(0, cash);
    _emit();
    return cash;
  }

  @override
  Future<List<CashAccount>> getWallets({bool includeClosed = false}) async {
    final wallets = _accounts
        .where((a) => a.id != _cashAccountId)
        .toList(growable: false);
    if (includeClosed) return wallets;
    return wallets.where((a) => !a.isClosed).toList(growable: false);
  }

  // ------------------------------------------------------------
  // WALLET CRUD
  // ------------------------------------------------------------

  @override
  Future<CashAccount> createWallet(CashAccount wallet) async {
    _accounts.add(wallet);
    _emit();
    return wallet;
  }

  @override
  Future<CashAccount> updateWallet(CashAccount wallet) async {
    final index = _indexOf(wallet.id);
    if (index == -1) return wallet;

    _accounts[index] = wallet;
    _emit();
    return wallet;
  }

  @override
  Future<void> deleteWallet(String id) async {
    // Do not allow deleting the "Cash in hand" account
    if (id == _cashAccountId) return;

    _accounts.removeWhere((a) => a.id == id);
    _emit();
  }

  // ------------------------------------------------------------
  // CLOSE / REOPEN
  // ------------------------------------------------------------

  @override
  Future<void> closeWallet(String id, {DateTime? closedAt}) async {
    // Do not allow closing "Cash in hand"
    if (id == _cashAccountId) return;

    final index = _indexOf(id);
    if (index == -1) return;

    final current = _accounts[index];
    final updated = current.copyWith(
      isClosed: true,
      closedAt: closedAt ?? DateTime.now(),
    );

    _accounts[index] = updated;
    _emit();
  }

  @override
  Future<void> reopenWallet(String id) async {
    final index = _indexOf(id);
    if (index == -1) return;

    final current = _accounts[index];
    final updated = current.copyWith(isClosed: false, closedAt: null);

    _accounts[index] = updated;
    _emit();
  }

  // ------------------------------------------------------------
  // BALANCE OPERATIONS
  // ------------------------------------------------------------

  @override
  Future<void> adjustBalance({
    required String accountId,
    required double delta,
  }) async {
    final index = _indexOf(accountId);
    if (index == -1) return;

    final current = _accounts[index];
    final updated = current.copyWith(balance: current.balance + delta);

    _accounts[index] = updated;
    _emit();
  }

  @override
  Future<void> overrideBalance({
    required String accountId,
    required double newBalance,
  }) async {
    final index = _indexOf(accountId);
    if (index == -1) return;

    final current = _accounts[index];
    final updated = current.copyWith(balance: newBalance);

    _accounts[index] = updated;
    _emit();
  }

  // ------------------------------------------------------------
  // SEED DATA
  // ------------------------------------------------------------

  static final List<CashAccount> _defaultAccounts = [
    const CashAccount(id: _cashAccountId, name: 'Cash in hand', balance: 0.0),
    const CashAccount(
      id: 'wallet-paytm',
      name: 'Paytm wallet',
      balance: 1500.0,
    ),
  ];
}
