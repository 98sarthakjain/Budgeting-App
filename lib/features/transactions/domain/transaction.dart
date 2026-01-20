// lib/features/transactions/domain/transaction.dart

/// Core money movement semantics for a single account.
///
/// All amounts are stored as positive numbers. The [TransactionType] and
/// [AdjustmentDirection] decide how they affect balances and reports.
enum TransactionType {
  income,
  expense,
  transferIn,
  transferOut,
  openingBalance,
  adjustment,
}

/// Direction of an adjustment relative to the current ledger balance.
///
/// - [increase]: real-world balance is higher than the computed ledger balance
/// - [decrease]: real-world balance is lower than the computed ledger balance
enum AdjustmentDirection { increase, decrease }

/// A single transaction affecting one account.
///
/// Balances are computed by summing transactions according to the global
/// financial rules (see lib/docs/global_financial_rules.md).
class Transaction {
  final String id;

  /// The primary account this transaction affects.
  final String accountId;

  /// When the transaction is considered to have happened (user-facing date).
  final DateTime bookingDate;

  /// When this transaction was created in the system.
  final DateTime createdAt;

  /// When this transaction was last modified.
  final DateTime updatedAt;

  /// Positive numeric amount.
  ///
  /// The semantic (credit/debit) is determined by [type] and
  /// [adjustmentDirection], not by the sign of this field.
  final double amount;

  /// Core type of the transaction.
  final TransactionType type;

  /// Direction of an adjustment, when [type] is [TransactionType.adjustment].
  ///
  /// Must be null for all other transaction types.
  final AdjustmentDirection? adjustmentDirection;

  /// Optional identifier linking legs of a transfer.
  ///
  /// For a transfer between accounts A and B, both the transferOut on A and the
  /// transferIn on B share the same [transferGroupId].
  final String? transferGroupId;

  /// Optional counter-account identifier.
  ///
  /// - For transfers: the other account id.
  /// - For income/expense: can be used for merchant/payee later.
  final String? counterAccountId;

  /// Optional category identifier for analytics.
  ///
  /// Ignored for [TransactionType.openingBalance] and
  /// [TransactionType.adjustment] when computing income/expense reports.
  final String? categoryId;

  /// Short label shown in lists (e.g. "Groceries", "Salary Dec").
  final String? description;

  /// Optional longer free-text notes.
  final String? notes;

  /// Optional tags for search/analytics. Reserved for future use.
  final List<String> tags;

  /// Whether the transaction has cleared/posted.
  ///
  /// For v1, this can always be true. It becomes useful for card holds,
  /// pending UPI payments, etc.
  final bool isCleared;

  const Transaction({
    required this.id,
    required this.accountId,
    required this.bookingDate,
    required this.createdAt,
    required this.updatedAt,
    required this.amount,
    required this.type,
    this.adjustmentDirection,
    this.transferGroupId,
    this.counterAccountId,
    this.categoryId,
    this.description,
    this.notes,
    this.tags = const [],
    this.isCleared = true,
  });

  /// Convenience helper for creating a modified copy.
  Transaction copyWith({
    String? id,
    String? accountId,
    DateTime? bookingDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? amount,
    TransactionType? type,
    AdjustmentDirection? adjustmentDirection,
    String? transferGroupId,
    String? counterAccountId,
    String? categoryId,
    String? description,
    String? notes,
    List<String>? tags,
    bool? isCleared,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      bookingDate: bookingDate ?? this.bookingDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      adjustmentDirection: adjustmentDirection ?? this.adjustmentDirection,
      transferGroupId: transferGroupId ?? this.transferGroupId,
      counterAccountId: counterAccountId ?? this.counterAccountId,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      isCleared: isCleared ?? this.isCleared,
    );
  }
}

/// Aggregated income/expense summary for dashboards/analytics.
///
/// This intentionally excludes:
/// - transfers
/// - openingBalance
/// - adjustment
class IncomeExpenseSummary {
  final double totalIncome;
  final double totalExpense;

  const IncomeExpenseSummary({
    required this.totalIncome,
    required this.totalExpense,
  });
}
