// lib/features/cash/data/cash_account_repository.dart

import 'package:budgeting_app/features/cash/domain/cash_account.dart';

/// Repository for "liquid money" accounts:
/// - One special "Cash in hand" account
/// - Zero or more digital wallets (Paytm, PhonePe, etc.)
abstract class CashAccountRepository {
  // ------------------------------------------------------------
  // QUERIES
  // ------------------------------------------------------------

  /// All cash-like accounts (cash + wallets).
  ///
  /// By default, closed accounts are excluded. Use [includeClosed] = true
  /// for screens like "All accounts" or history filters.
  Future<List<CashAccount>> getAllAccounts({bool includeClosed = false});

  /// Reactive variant for screens that should update on changes.
  ///
  /// By default, emits only open accounts. Pass [includeClosed] = true
  /// for admin / history views.
  Stream<List<CashAccount>> watchAllAccounts({bool includeClosed = false});

  /// Fetch a single account by id.
  Future<CashAccount?> getById(String id);

  /// Returns the single "Cash in hand" account.
  ///
  /// Implementations must ensure this always exists
  /// (creating it on first access if needed).
  Future<CashAccount> getCashAccount();

  /// Convenience helper to get only wallets (no pure cash).
  ///
  /// By default, closed wallets are excluded unless [includeClosed] = true.
  Future<List<CashAccount>> getWallets({bool includeClosed = false});

  // ------------------------------------------------------------
  // WALLET CRUD (cash is not created/deleted here)
  // ------------------------------------------------------------

  /// Create a new digital wallet.
  ///
  /// Domain-level validation should ensure this represents a wallet.
  Future<CashAccount> createWallet(CashAccount wallet);

  /// Update an existing wallet's metadata (name, etc.).
  Future<CashAccount> updateWallet(CashAccount wallet);

  /// Delete a wallet by id.
  ///
  /// Implementations should:
  /// - NOT allow deleting the core "Cash in hand" account.
  /// - Prefer "close" when there are transactions (handled in UI layer).
  Future<void> deleteWallet(String id);

  // ------------------------------------------------------------
  // CLOSE / REOPEN
  // ------------------------------------------------------------

  /// Mark a wallet as closed (no new use, but history retained).
  ///
  /// Typically used when the user stops using a wallet, but wants
  /// transaction history to remain intact.
  Future<void> closeWallet(String id, {DateTime? closedAt});

  /// Reopen a previously closed wallet.
  Future<void> reopenWallet(String id);

  // ------------------------------------------------------------
  // BALANCE OPERATIONS (used by Transactions & manual overrides)
  // ------------------------------------------------------------

  /// Adjust the balance of a cash or wallet account.
  ///
  /// Used when recording transactions:
  ///  - Expense paid from this account  → delta = -amount
  ///  - Income received in this account → delta = +amount
  Future<void> adjustBalance({
    required String accountId,
    required double delta,
  });

  /// Override the balance with an authoritative value.
  ///
  /// Example:
  ///  - You count your physical cash and it's ₹5,200
  ///  - You see your Paytm balance and set it to match.
  Future<void> overrideBalance({
    required String accountId,
    required double newBalance,
  });

  // ------------------------------------------------------------
  // LEGACY COMPAT WRAPPER (for existing UI using getAll)
  // ------------------------------------------------------------

  /// Legacy alias for older code that still calls [getAll].
  /// Internally delegates to [getAllAccounts].
  Future<List<CashAccount>> getAll() => getAllAccounts();
}
