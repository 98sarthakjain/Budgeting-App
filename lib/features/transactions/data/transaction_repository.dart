// lib/features/transactions/data/transaction_repository.dart

import 'package:budgeting_app/features/transactions/domain/transaction.dart';

/// Abstract repository for working with ledger transactions.
///
/// Implementations:
/// - v1: InMemoryTransactionRepository
/// - v2: HiveTransactionRepository
///
/// All account modules (savings, cash, wallets, cards, loans, investments)
/// should depend on this abstraction instead of talking directly to storage.
abstract class TransactionRepository {
  // ---------------------------------------------------------------------------
  // WATCH
  // ---------------------------------------------------------------------------

  /// Emits an event whenever the ledger changes.
  ///
  /// Screens can listen to this to refresh derived totals (balances, dues,
  /// summaries) without having to manually plumb callbacks through navigation.
  Stream<void> watchAll();

  // ---------------------------------------------------------------------------
  // CREATE
  // ---------------------------------------------------------------------------

  /// Simple income (salary, interest, refunds, etc.).
  Future<Transaction> createIncome({
    required String accountId,
    required double amount,
    required DateTime bookingDate,
    String? categoryId,
    String? description,
    String? notes,
    List<String> tags,
  });

  /// Simple expense (UPI, card swipe, bill payment, etc.).
  Future<Transaction> createExpense({
    required String accountId,
    required double amount,
    required DateTime bookingDate,
    String? categoryId,
    String? description,
    String? notes,
    List<String> tags,
  });

  /// Opening balance when an account is first added to the app.
  ///
  /// Typically called once per account. The app may enforce this constraint.
  Future<Transaction> createOpeningBalance({
    required String accountId,
    required double amount,
    required DateTime bookingDate,
    String? description,
  });

  /// Adjustment to reconcile ledger balance with real-world balance.
  ///
  /// Usage pattern in UI:
  ///   - compute ledgerBalance via repository
  ///   - delta = actual - ledgerBalance
  ///   - if delta != 0: createAdjustment(accountId, abs(delta), direction)
  Future<Transaction> createAdjustment({
    required String accountId,
    required double amount,
    required AdjustmentDirection direction,
    required DateTime bookingDate,
    String? description,
    String? notes,
  });

  /// Transfer between two accounts.
  ///
  /// Must create TWO transactions:
  ///   - transferOut on [fromAccountId]
  ///   - transferIn  on [toAccountId]
  ///
  /// Both legs share the same [transferGroupId].
  ///
  /// Returns the pair of transactions in a list.
  Future<List<Transaction>> createTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required DateTime bookingDate,
    String? description,
    String? notes,
  });

  // ---------------------------------------------------------------------------
  // UPDATE / DELETE
  // ---------------------------------------------------------------------------

  /// Replace an existing transaction with an updated version.
  ///
  /// The implementation may enforce invariants, such as:
  /// - type not changing from income to transfer, etc., in certain cases
  /// - updatedAt being refreshed automatically
  Future<Transaction> updateTransaction(Transaction transaction);

  /// Delete a transaction.
  ///
  /// v1 can implement this as a hard delete from storage.
  /// A future version may preserve a tombstone for audit.
  Future<void> deleteTransaction(String id);

  // ---------------------------------------------------------------------------
  // READ / QUERY
  // ---------------------------------------------------------------------------

  Future<Transaction?> getById(String id);

  /// All transactions for a given account, optionally filtered by date.
  Future<List<Transaction>> getByAccount({
    required String accountId,
    DateTime? from, // inclusive
    DateTime? to, // inclusive
  });

  /// Reactive variant for per-account transaction lists.
  Stream<List<Transaction>> watchByAccount({
    required String accountId,
    DateTime? from, // inclusive
    DateTime? to, // inclusive
  });

  /// Lightweight helper to check if ANY transactions exist for an account.
  ///
  /// Used by account modules (Savings, Cash, Cards, Loans, etc.) to decide
  /// whether an account can be hard deleted, or must be closed instead.
  Future<bool> hasAnyForAccount(String accountId);

  /// Generic query for analytics / reporting.
  ///
  /// v1 implementations can do this in-memory; later revisions may push more
  /// filtering down into storage.
  Future<List<Transaction>> query({
    List<String>? accountIds,
    List<TransactionType>? types,
    String? categoryId,
    DateTime? from,
    DateTime? to,
    bool? onlyCleared,
    String? textSearch,
  });

  // ---------------------------------------------------------------------------
  // BALANCE HELPERS
  // ---------------------------------------------------------------------------

  /// Compute balance as of [until] (or now if null) for a single account,
  /// applying the global financial rules.
  Future<double> computeBalance({required String accountId, DateTime? until});

  /// Compute aggregated income/expense for dashboards & reports.
  ///
  /// Implementation must:
  ///  - INCLUDE: income, expense
  ///  - EXCLUDE: transferIn/transferOut, openingBalance, adjustment
  Future<IncomeExpenseSummary> computeIncomeExpenseSummary({
    List<String>? accountIds,
    DateTime? from,
    DateTime? to,
  });
}
