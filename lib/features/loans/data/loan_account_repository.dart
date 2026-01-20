// lib/features/loans/data/loan_account_repository.dart

import 'package:budgeting_app/features/loans/domain/loan_account.dart';

abstract class LoanAccountRepository {
  Future<List<LoanAccount>> getAllLoans();
  Future<LoanAccount?> getById(String id);
}
