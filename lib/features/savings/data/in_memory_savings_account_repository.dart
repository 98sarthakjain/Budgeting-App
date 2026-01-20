// lib/features/savings/data/in_memory_savings_account_repository.dart

import 'dart:async';

import 'package:budgeting_app/features/savings/data/savings_account_repository.dart';
import 'package:budgeting_app/features/savings/domain/savings_account.dart';

class InMemorySavingsAccountRepository implements SavingsAccountRepository {
  final List<SavingsAccount> _accounts;
  final StreamController<List<SavingsAccount>> _controller =
      StreamController<List<SavingsAccount>>.broadcast();

  InMemorySavingsAccountRepository({List<SavingsAccount>? seed})
    : _accounts = seed ?? _defaultAccounts {
    // Emit initial state
    _emit();
  }

  void _emit() {
    _controller.add(List.unmodifiable(_accounts));
  }

  // ------------------------------------------------------------
  // QUERY
  // ------------------------------------------------------------

  @override
  Future<List<SavingsAccount>> getAllAccounts({
    bool includeClosed = false,
  }) async {
    if (includeClosed) {
      return List.unmodifiable(_accounts);
    }
    return List.unmodifiable(_accounts.where((a) => !a.isClosed));
  }

  @override
  Future<SavingsAccount?> getById(String id) async {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<SavingsAccount>> watchAllAccounts({bool includeClosed = false}) {
    // Wrap the internal stream so each subscriber gets filtered
    // according to [includeClosed], similar to TransactionRepository.watchByAccount.
    final controller = StreamController<List<SavingsAccount>>();

    void emitFiltered(List<SavingsAccount> all) {
      if (includeClosed) {
        controller.add(List.unmodifiable(all));
      } else {
        controller.add(List.unmodifiable(all.where((a) => !a.isClosed)));
      }
    }

    // Push current snapshot immediately
    emitFiltered(_accounts);

    final sub = _controller.stream.listen(emitFiltered);

    controller.onCancel = () {
      sub.cancel();
    };

    return controller.stream;
  }

  // ------------------------------------------------------------
  // CRUD
  // ------------------------------------------------------------

  @override
  Future<SavingsAccount> createAccount(SavingsAccount account) async {
    _accounts.add(account);
    _emit();
    return account;
  }

  @override
  Future<SavingsAccount> updateAccount(SavingsAccount account) async {
    final index = _accounts.indexWhere((a) => a.id == account.id);
    if (index == -1) return account;

    _accounts[index] = account;
    _emit();
    return account;
  }

  @override
  Future<void> closeAccount(String id) async {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index == -1) return;

    final current = _accounts[index];
    if (current.isClosed) return;

    _accounts[index] = current.copyWith(
      isClosed: true,
      closedAt: DateTime.now(),
    );
    _emit();
  }

  @override
  Future<void> reopenAccount(String id) async {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index == -1) return;

    final current = _accounts[index];
    if (!current.isClosed) return;

    _accounts[index] = current.copyWith(isClosed: false, closedAt: null);
    _emit();
  }

  @override
  Future<void> deleteAccount(String id) async {
    _accounts.removeWhere((a) => a.id == id);
    _emit();
  }

  // ------------------------------------------------------------
  // BALANCE ADJUSTMENT LOGIC
  // ------------------------------------------------------------

  @override
  Future<void> adjustBalances({
    required String accountId,
    required double currentBalanceDelta,
    required double availableBalanceDelta,
  }) async {
    final index = _accounts.indexWhere((a) => a.id == accountId);
    if (index == -1) return;

    final current = _accounts[index];
    final updated = current.copyWith(
      currentBalance: current.currentBalance + currentBalanceDelta,
      availableBalance: current.availableBalance + availableBalanceDelta,
    );

    _accounts[index] = updated;
    _emit();
  }

  @override
  Future<void> overrideBalances({
    required String accountId,
    required double currentBalance,
    required double availableBalance,
  }) async {
    final index = _accounts.indexWhere((a) => a.id == accountId);
    if (index == -1) return;

    final current = _accounts[index];
    final updated = current.copyWith(
      currentBalance: currentBalance,
      availableBalance: availableBalance,
    );

    _accounts[index] = updated;
    _emit();
  }

  // ------------------------------------------------------------
  // SEED DATA (unchanged)
  // ------------------------------------------------------------

  static final List<SavingsAccount> _defaultAccounts = [
    SavingsAccount(
      id: 'axis-salary',
      bankName: 'Axis Bank',
      accountNickname: 'Salary account',
      accountType: 'Savings',
      maskedAccountNumber: 'XXXX 1234',
      ifsc: 'UTIB0000123',
      branchName: 'Koramangala Branch',
      currentBalance: 86540,
      availableBalance: 86540,
      interestRate: 3.50,
      minBalanceRequired: 0,
      isSalaryAccount: true,
      hasNominee: true,
      lastInterestCreditedOn: DateTime.now().subtract(const Duration(days: 35)),
      lastInterestAmount: 742.20,
    ),
    SavingsAccount(
      id: 'hdfc-main',
      bankName: 'HDFC Bank',
      accountNickname: 'Main savings',
      accountType: 'Savings',
      maskedAccountNumber: 'XXXX 5678',
      ifsc: 'HDFC0000456',
      branchName: 'Indiranagar Branch',
      currentBalance: 245000,
      availableBalance: 245000,
      interestRate: 3.00,
      minBalanceRequired: 10000,
      isSalaryAccount: false,
      hasNominee: true,
      lastInterestCreditedOn: DateTime.now().subtract(const Duration(days: 32)),
      lastInterestAmount: 610.80,
    ),
    SavingsAccount(
      id: 'sbi-nre',
      bankName: 'SBI',
      accountNickname: 'NRE account',
      accountType: 'NRE',
      maskedAccountNumber: 'XXXX 9101',
      ifsc: 'SBIN0000789',
      branchName: 'MG Road Branch',
      currentBalance: 410000,
      availableBalance: 410000,
      interestRate: 6.00,
      minBalanceRequired: 0,
      isSalaryAccount: false,
      hasNominee: false,
      lastInterestCreditedOn: DateTime.now().subtract(const Duration(days: 40)),
      lastInterestAmount: 2000.00,
    ),
  ];
}
