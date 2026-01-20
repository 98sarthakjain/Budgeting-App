// lib/features/cash/domain/cash_account.dart

class CashAccount {
  final String id;
  final String name;
  final double balance;

  /// Whether this wallet/cash account is closed (no longer active for new use).
  final bool isClosed;

  /// When the account was closed, if applicable.
  final DateTime? closedAt;

  const CashAccount({
    required this.id,
    required this.name,
    required this.balance,
    this.isClosed = false,
    this.closedAt,
  });

  CashAccount copyWith({
    String? name,
    double? balance,
    bool? isClosed,
    DateTime? closedAt,
  }) {
    return CashAccount(
      id: id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      isClosed: isClosed ?? this.isClosed,
      closedAt: closedAt ?? this.closedAt,
    );
  }
}
