// lib/features/savings/domain/savings_account.dart

class SavingsAccount {
  final String id;
  final String bankName;
  final String accountNickname; // e.g. "Salary Account"
  final String accountType; // e.g. "Savings", "Salary", "NRE"
  final String maskedAccountNumber; // e.g. "XXXX 1234"
  final String ifsc;
  final String branchName;

  final double currentBalance;
  final double availableBalance;

  /// Interest rate in % per annum
  final double interestRate;

  /// Minimum balance requirement for Indian savings accounts
  final double minBalanceRequired;

  /// For salary-linked zero balance accounts
  final bool isSalaryAccount;

  /// Whether nominee details are registered
  final bool hasNominee;

  final DateTime lastInterestCreditedOn;
  final double lastInterestAmount;

  /// Whether this account is closed (no new transactions, hidden from active lists).
  final bool isClosed;

  /// When the account was closed, if applicable.
  final DateTime? closedAt;

  const SavingsAccount({
    required this.id,
    required this.bankName,
    required this.accountNickname,
    required this.accountType,
    required this.maskedAccountNumber,
    required this.ifsc,
    required this.branchName,
    required this.currentBalance,
    required this.availableBalance,
    required this.interestRate,
    required this.minBalanceRequired,
    required this.isSalaryAccount,
    required this.hasNominee,
    required this.lastInterestCreditedOn,
    required this.lastInterestAmount,
    this.isClosed = false,
    this.closedAt,
  });

  /// Creates a copy of this [SavingsAccount] with the given fields replaced.
  SavingsAccount copyWith({
    String? id,
    String? bankName,
    String? accountNickname,
    String? accountType,
    String? maskedAccountNumber,
    String? ifsc,
    String? branchName,
    double? currentBalance,
    double? availableBalance,
    double? interestRate,
    double? minBalanceRequired,
    bool? isSalaryAccount,
    bool? hasNominee,
    DateTime? lastInterestCreditedOn,
    double? lastInterestAmount,
    bool? isClosed,
    DateTime? closedAt,
  }) {
    return SavingsAccount(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      accountNickname: accountNickname ?? this.accountNickname,
      accountType: accountType ?? this.accountType,
      maskedAccountNumber: maskedAccountNumber ?? this.maskedAccountNumber,
      ifsc: ifsc ?? this.ifsc,
      branchName: branchName ?? this.branchName,
      currentBalance: currentBalance ?? this.currentBalance,
      availableBalance: availableBalance ?? this.availableBalance,
      interestRate: interestRate ?? this.interestRate,
      minBalanceRequired: minBalanceRequired ?? this.minBalanceRequired,
      isSalaryAccount: isSalaryAccount ?? this.isSalaryAccount,
      hasNominee: hasNominee ?? this.hasNominee,
      lastInterestCreditedOn:
          lastInterestCreditedOn ?? this.lastInterestCreditedOn,
      lastInterestAmount: lastInterestAmount ?? this.lastInterestAmount,
      isClosed: isClosed ?? this.isClosed,
      closedAt: closedAt ?? this.closedAt,
    );
  }
}
