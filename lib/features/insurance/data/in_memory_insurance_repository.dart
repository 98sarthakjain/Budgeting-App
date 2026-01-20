import 'package:budgeting_app/features/insurance/data/insurance_repository.dart';
import 'package:budgeting_app/features/insurance/domain/insurance_policy.dart';

class InMemoryInsuranceRepository implements InsuranceRepository {
  final List<InsurancePolicy> _policies;

  InMemoryInsuranceRepository({List<InsurancePolicy>? seed})
    : _policies = seed ?? _default;

  @override
  Future<List<InsurancePolicy>> getAll() async => _policies;

  @override
  Future<InsurancePolicy?> getById(String id) async {
    try {
      return _policies.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static final List<InsurancePolicy> _default = [
    InsurancePolicy(
      id: 'life-hdfc',
      insurerName: 'HDFC Life',
      policyName: 'Click 2 Protect',
      type: InsuranceType.term,
      policyNumber: 'HDFC12345678',
      expiryDate: DateTime(2026, 3, 12),
      premiumAmount: 8500.0,
      sumInsured: 10000000.0,
      autoRenew: true,
    ),
    InsurancePolicy(
      id: 'health-star',
      insurerName: 'Star Health',
      policyName: 'Family Floater',
      type: InsuranceType.health,
      policyNumber: 'STAR99887766',
      expiryDate: DateTime(2025, 12, 5),
      premiumAmount: 22000.0,
      sumInsured: 500000.0,
      autoRenew: false,
    ),
  ];
}
