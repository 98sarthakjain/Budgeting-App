import 'package:budgeting_app/features/investments/domain/investment_type.dart';

class InvestmentAccount {
  final String id;
  final InvestmentType type;
  final String name;
  final double investedAmount;
  final double currentValue;
  final double profitLoss;
  final double xirr; // annualized return
  final String category; // e.g., Large Cap, Mid Cap, Debt Fund
  final String institution; // SIP house, stock broker, NPS POP
  final String? folioNumber;

  const InvestmentAccount({
    required this.id,
    required this.type,
    required this.name,
    required this.investedAmount,
    required this.currentValue,
    required this.profitLoss,
    required this.xirr,
    required this.category,
    required this.institution,
    this.folioNumber,
  });
}
