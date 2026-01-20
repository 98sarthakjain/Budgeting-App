import 'package:flutter/foundation.dart';
import 'package:budgeting_app/features/savings/domain/account.dart';

/// In-memory store for accounts (savings, cash, wallets).
/// Right now, only used by the ledger; no Hive yet.
class AccountStore extends ChangeNotifier {
  AccountStore._internal() {
    // Create some default accounts so the app can work even before
    // we build "Add account" UI.
    _accounts.addAll([
      const Account(
        id: 'savings_default',
        name: 'Main savings',
        type: AccountType.savings,
        balance: 0,
      ),
      const Account(
        id: 'cash_default',
        name: 'Cash',
        type: AccountType.cash,
        balance: 0,
      ),
    ]);
  }

  static final AccountStore instance = AccountStore._internal();

  final List<Account> _accounts = [];

  List<Account> get accounts => List.unmodifiable(_accounts);

  List<Account> get savingsAccounts =>
      _accounts.where((a) => a.type == AccountType.savings).toList();

  List<Account> get cashAccounts =>
      _accounts.where((a) => a.type == AccountType.cash).toList();

  Account? getById(String id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  void addAccount(Account account) {
    _accounts.add(account);
    notifyListeners();
  }

  /// Apply a delta to a given account's balance.
  /// Positive delta -> increase balance; negative -> decrease.
  void applyBalanceDelta(String accountId, double delta) {
    final index = _accounts.indexWhere((a) => a.id == accountId);
    if (index == -1) return;

    final current = _accounts[index];
    final updated = current.copyWith(balance: current.balance + delta);
    _accounts[index] = updated;
    notifyListeners();
  }

  double get totalSavings => _accounts
      .where((a) => a.type == AccountType.savings)
      .fold(0.0, (sum, a) => sum + a.balance);

  double get totalCash => _accounts
      .where((a) => a.type == AccountType.cash)
      .fold(0.0, (sum, a) => sum + a.balance);
}
