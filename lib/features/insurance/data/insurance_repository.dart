import 'package:budgeting_app/features/insurance/domain/insurance_policy.dart';

abstract class InsuranceRepository {
  Future<List<InsurancePolicy>> getAll();
  Future<InsurancePolicy?> getById(String id);
}
