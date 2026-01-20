import 'package:budgeting_app/features/investments/domain/investment_account.dart';
import 'package:budgeting_app/features/investments/domain/investment_type.dart';

abstract class InvestmentRepository {
  Future<List<InvestmentAccount>> getAll();
  Future<List<InvestmentAccount>> getByType(InvestmentType type);
  Future<InvestmentAccount?> getById(String id);
}
