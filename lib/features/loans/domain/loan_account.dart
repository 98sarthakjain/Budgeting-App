// lib/features/loans/domain/loan_account.dart

enum LoanRateType { fixed, floating }

class LoanAccount {
  final String id;
  final String bankName;
  final String loanNickname; // "Home loan - SBI"
  final String loanType; // "Home", "Car", "Personal", etc.
  final String maskedAccountNumber; // "XXXX 1234"

  /// Original sanctioned loan amount.
  final double principalAmount;

  /// Current outstanding principal.
  final double outstandingPrincipal;

  /// Current interest rate (per annum, %).
  final double interestRateAnnual;

  /// Original tenure in months.
  final int originalTenureMonths;

  /// Remaining tenure in months (as of now).
  final int remainingTenureMonths;

  /// Current EMI amount (monthly).
  final double emiAmount;

  final DateTime nextEmiDueDate;
  final DateTime lastEmiPaidDate;
  final double lastEmiAmount;

  final LoanRateType rateType;

  const LoanAccount({
    required this.id,
    required this.bankName,
    required this.loanNickname,
    required this.loanType,
    required this.maskedAccountNumber,
    required this.principalAmount,
    required this.outstandingPrincipal,
    required this.interestRateAnnual,
    required this.originalTenureMonths,
    required this.remainingTenureMonths,
    required this.emiAmount,
    required this.nextEmiDueDate,
    required this.lastEmiPaidDate,
    required this.lastEmiAmount,
    required this.rateType,
  });
}
