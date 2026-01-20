enum InsuranceType { health, life, term, motor, travel, home }

class InsurancePolicy {
  final String id;
  final String insurerName;
  final String policyName;
  final InsuranceType type;
  final String policyNumber;
  final DateTime expiryDate;
  final double premiumAmount;
  final double sumInsured;
  final bool autoRenew;

  const InsurancePolicy({
    required this.id,
    required this.insurerName,
    required this.policyName,
    required this.type,
    required this.policyNumber,
    required this.expiryDate,
    required this.premiumAmount,
    required this.sumInsured,
    required this.autoRenew,
  });
}
