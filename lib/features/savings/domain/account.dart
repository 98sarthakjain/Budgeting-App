// lib/features/accounts/domain/account.dart

/// Generic account used by AccountStore + transactions:
/// - type: savings / cash
/// - balance: current account balance

enum AccountType { savings, cash }

class Account {
  final String id;
  final String name;
  final AccountType type;
  final double balance;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
  });

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? balance,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
    );
  }
}
