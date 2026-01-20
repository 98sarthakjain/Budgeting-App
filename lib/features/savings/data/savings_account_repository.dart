// lib/features/savings/data/savings_account_repository.dart

import 'package:budgeting_app/features/savings/domain/savings_account.dart';

/// Core contract for savings account storage.
/// Implementations: in-memory, Hive (later local + remote sync).
abstract class SavingsAccountRepository {
  // ------------------------------------------------------------
  // QUERY
  // ------------------------------------------------------------

  /// All accounts (used by list screen & home summary).
  ///
  /// By default, returns only active (non-closed) accounts.
  /// Pass [includeClosed] = true to also include closed accounts.
  Future<List<SavingsAccount>> getAllAccounts({bool includeClosed = false});

  /// Fetch a single account by id.
  Future<SavingsAccount?> getById(String id);

  /// Emits updated list when accounts change.
  /// In-memory version will be a simple broadcast stream.
  Stream<List<SavingsAccount>> watchAllAccounts({bool includeClosed = false});

  // ------------------------------------------------------------
  // CRUD
  // ------------------------------------------------------------

  /// Create a new savings account.
  Future<SavingsAccount> createAccount(SavingsAccount account);

  /// Update metadata of an existing account.
  Future<SavingsAccount> updateAccount(SavingsAccount account);

  /// Mark an account as closed (no new transactions, hidden from active lists).
  ///
  /// Historical transactions remain untouched to keep reports correct.
  Future<void> closeAccount(String id);

  /// Re-open a previously closed account.
  ///
  /// Useful if a user accidentally closed an account or reuses it.
  Future<void> reopenAccount(String id);

  /// Delete an account.
  ///
  /// Global rule: only allowed when there are **no transactions** for this
  /// account in the ledger. Otherwise, the UI should call [closeAccount]
  /// instead of delete.
  Future<void> deleteAccount(String id);

  // ------------------------------------------------------------
  // BALANCE OPERATIONS (for Transactions integration)
  // ------------------------------------------------------------

  /// Adjust balances in response to a transaction.
  ///
  /// Example:
  ///  - Expense paid from this account → delta = -500
  ///  - Income received in this account → delta = +10000
  Future<void> adjustBalances({
    required String accountId,
    required double currentBalanceDelta,
    required double availableBalanceDelta,
  });

  /// Override balances manually (e.g. reconcile with bank statement).
  Future<void> overrideBalances({
    required String accountId,
    required double currentBalance,
    required double availableBalance,
  });
}
