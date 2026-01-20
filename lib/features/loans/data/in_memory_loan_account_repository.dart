// lib/features/loans/data/in_memory_loan_account_repository.dart

import 'package:budgeting_app/features/loans/data/loan_account_repository.dart';
import 'package:budgeting_app/features/loans/domain/loan_account.dart';

class InMemoryLoanAccountRepository implements LoanAccountRepository {
  final List<LoanAccount> _loans;

  InMemoryLoanAccountRepository({List<LoanAccount>? seed})
    : _loans = seed ?? _defaultLoans;

  @override
  Future<List<LoanAccount>> getAllLoans() async => _loans;

  @override
  Future<LoanAccount?> getById(String id) async {
    try {
      return _loans.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  static final List<LoanAccount> _defaultLoans = [
    LoanAccount(
      id: 'home-sbi',
      bankName: 'SBI',
      loanNickname: 'Home Loan - Delhi Flat',
      loanType: 'Home',
      maskedAccountNumber: 'XXXX 4321',
      principalAmount: 8_750_000,
      outstandingPrincipal: 6_200_000,
      interestRateAnnual: 8.35,
      originalTenureMonths: 240,
      remainingTenureMonths: 196,
      emiAmount: 67_902,
      nextEmiDueDate: DateTime.now().add(const Duration(days: 12)),
      lastEmiPaidDate: DateTime.now().subtract(const Duration(days: 18)),
      lastEmiAmount: 67_902,
      rateType: LoanRateType.floating,
    ),
    LoanAccount(
      id: 'car-hdfc',
      bankName: 'HDFC Bank',
      loanNickname: 'Car Loan - Nexon EV',
      loanType: 'Car',
      maskedAccountNumber: 'XXXX 9876',
      principalAmount: 1_400_000,
      outstandingPrincipal: 980_000,
      interestRateAnnual: 9.25,
      originalTenureMonths: 84,
      remainingTenureMonths: 60,
      emiAmount: 24_500,
      nextEmiDueDate: DateTime.now().add(const Duration(days: 5)),
      lastEmiPaidDate: DateTime.now().subtract(const Duration(days: 25)),
      lastEmiAmount: 24_500,
      rateType: LoanRateType.fixed,
    ),
  ];
}
