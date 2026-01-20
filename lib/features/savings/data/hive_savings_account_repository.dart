// lib/features/savings/data/hive_savings_account_repository.dart

import 'dart:async';

import 'package:hive/hive.dart';

import 'package:budgeting_app/features/savings/data/savings_account_repository.dart';
import 'package:budgeting_app/features/savings/domain/savings_account.dart';

/// Hive-backed implementation of [SavingsAccountRepository].
///
/// Stores plain maps to keep schema evolution easy.
class HiveSavingsAccountRepository implements SavingsAccountRepository {
  final Box _box;

  HiveSavingsAccountRepository(this._box);

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> _toMap(SavingsAccount a) => {
        'id': a.id,
        'bankName': a.bankName,
        'accountNickname': a.accountNickname,
        'accountType': a.accountType,
        'maskedAccountNumber': a.maskedAccountNumber,
        'ifsc': a.ifsc,
        'branchName': a.branchName,
        'currentBalance': a.currentBalance,
        'availableBalance': a.availableBalance,
        'interestRate': a.interestRate,
        'minBalanceRequired': a.minBalanceRequired,
        'isSalaryAccount': a.isSalaryAccount,
        'hasNominee': a.hasNominee,
        'lastInterestCreditedOn': a.lastInterestCreditedOn.millisecondsSinceEpoch,
        'lastInterestAmount': a.lastInterestAmount,
        'isClosed': a.isClosed,
        'closedAt': a.closedAt?.millisecondsSinceEpoch,
      };

  static SavingsAccount _fromMap(Map m) => SavingsAccount(
        id: (m['id'] ?? '').toString(),
        bankName: (m['bankName'] ?? '').toString(),
        accountNickname: (m['accountNickname'] ?? '').toString(),
        accountType: (m['accountType'] ?? '').toString(),
        maskedAccountNumber: (m['maskedAccountNumber'] ?? '').toString(),
        ifsc: (m['ifsc'] ?? '').toString(),
        branchName: (m['branchName'] ?? '').toString(),
        currentBalance: (m['currentBalance'] is num)
            ? (m['currentBalance'] as num).toDouble()
            : 0.0,
        availableBalance: (m['availableBalance'] is num)
            ? (m['availableBalance'] as num).toDouble()
            : 0.0,
        interestRate: (m['interestRate'] is num)
            ? (m['interestRate'] as num).toDouble()
            : 0.0,
        minBalanceRequired: (m['minBalanceRequired'] is num)
            ? (m['minBalanceRequired'] as num).toDouble()
            : 0.0,
        isSalaryAccount: m['isSalaryAccount'] == true,
        hasNominee: m['hasNominee'] == true,
        lastInterestCreditedOn: m['lastInterestCreditedOn'] is num
            ? DateTime.fromMillisecondsSinceEpoch(
                (m['lastInterestCreditedOn'] as num).toInt(),
              )
            : DateTime.now(),
        lastInterestAmount: (m['lastInterestAmount'] is num)
            ? (m['lastInterestAmount'] as num).toDouble()
            : 0.0,
        isClosed: m['isClosed'] == true,
        closedAt: m['closedAt'] is num
            ? DateTime.fromMillisecondsSinceEpoch((m['closedAt'] as num).toInt())
            : null,
      );

  List<SavingsAccount> _all({required bool includeClosed}) {
    final all = _box.values
        .whereType<Map>()
        .map(_fromMap)
        .toList(growable: false);

    if (includeClosed) return all;
    return all.where((a) => !a.isClosed).toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  @override
  Future<List<SavingsAccount>> getAllAccounts({bool includeClosed = false}) async {
    return _all(includeClosed: includeClosed);
  }

  @override
  Stream<List<SavingsAccount>> watchAllAccounts({bool includeClosed = false}) async* {
    yield _all(includeClosed: includeClosed);
    yield* _box.watch().map((_) => _all(includeClosed: includeClosed));
  }

  @override
  Future<SavingsAccount?> getById(String id) async {
    final raw = _box.get(id);
    if (raw is! Map) return null;
    return _fromMap(raw);
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  @override
  Future<SavingsAccount> createAccount(SavingsAccount account) async {
    await _box.put(account.id, _toMap(account));
    return account;
  }

  @override
  Future<SavingsAccount> updateAccount(SavingsAccount account) async {
    await _box.put(account.id, _toMap(account));
    return account;
  }

  @override
  Future<void> deleteAccount(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> closeAccount(String id) async {
    final current = await getById(id);
    if (current == null) return;
    final updated = current.copyWith(isClosed: true, closedAt: DateTime.now());
    await _box.put(id, _toMap(updated));
  }

  @override
  Future<void> reopenAccount(String id) async {
    final current = await getById(id);
    if (current == null) return;
    final updated = current.copyWith(isClosed: false, closedAt: null);
    await _box.put(id, _toMap(updated));
  }

  // ---------------------------------------------------------------------------
  // Balance operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> adjustBalances({
    required String accountId,
    required double currentBalanceDelta,
    required double availableBalanceDelta,
  }) async {
    final current = await getById(accountId);
    if (current == null) return;
    final updated = current.copyWith(
      currentBalance: current.currentBalance + currentBalanceDelta,
      availableBalance: current.availableBalance + availableBalanceDelta,
    );
    await _box.put(accountId, _toMap(updated));
  }

  @override
  Future<void> overrideBalances({
    required String accountId,
    required double currentBalance,
    required double availableBalance,
  }) async {
    final current = await getById(accountId);
    if (current == null) return;
    final updated = current.copyWith(
      currentBalance: currentBalance,
      availableBalance: availableBalance,
    );
    await _box.put(accountId, _toMap(updated));
  }
}
