import 'package:budgeting_app/features/investments/data/investment_repository.dart';
import 'package:budgeting_app/features/investments/domain/investment_account.dart';
import 'package:budgeting_app/features/investments/domain/investment_type.dart';

class InMemoryInvestmentRepository implements InvestmentRepository {
  final List<InvestmentAccount> _items;

  InMemoryInvestmentRepository({List<InvestmentAccount>? seed})
    : _items = seed ?? _mock;

  @override
  Future<List<InvestmentAccount>> getAll() async => _items;

  @override
  Future<List<InvestmentAccount>> getByType(InvestmentType type) async {
    return _items.where((i) => i.type == type).toList();
  }

  @override
  Future<InvestmentAccount?> getById(String id) async {
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  static final List<InvestmentAccount> _mock = [
    InvestmentAccount(
      id: 'mf-largecap-1',
      type: InvestmentType.mutualFund,
      name: 'Nippon India Large Cap Fund',
      investedAmount: 120000,
      currentValue: 152500,
      profitLoss: 32500,
      xirr: 13.4,
      category: 'Large Cap',
      institution: 'Nippon AMC',
      folioNumber: '12345678',
    ),
    InvestmentAccount(
      id: 'mf-hybrid-1',
      type: InvestmentType.mutualFund,
      name: 'HDFC Hybrid Equity Fund',
      investedAmount: 65000,
      currentValue: 77800,
      profitLoss: 12800,
      xirr: 12.1,
      category: 'Hybrid',
      institution: 'HDFC AMC',
      folioNumber: '99887766',
    ),
    InvestmentAccount(
      id: 'stock-tata-1',
      type: InvestmentType.stock,
      name: 'Tata Motors Ltd',
      investedAmount: 44000,
      currentValue: 62000,
      profitLoss: 18000,
      xirr: 21.2,
      category: 'Auto Stock',
      institution: 'Zerodha',
      folioNumber: null,
    ),
    InvestmentAccount(
      id: 'nps-tier1',
      type: InvestmentType.nps,
      name: 'NPS Tier 1 - Auto Choice',
      investedAmount: 90000,
      currentValue: 118000,
      profitLoss: 28000,
      xirr: 10.8,
      category: 'Retirement',
      institution: 'LIC Pension Fund',
    ),
    InvestmentAccount(
      id: 'gld-sbi-etf',
      type: InvestmentType.gold,
      name: 'SBI Gold ETF',
      investedAmount: 45000,
      currentValue: 51800,
      profitLoss: 6800,
      xirr: 7.1,
      category: 'Gold',
      institution: 'SBI AMC',
    ),
    InvestmentAccount(
      id: 'fd-hdfc',
      type: InvestmentType.fd,
      name: 'HDFC Bank FD',
      investedAmount: 100000,
      currentValue: 112000,
      profitLoss: 12000,
      xirr: 6.8,
      category: 'Fixed Deposit',
      institution: 'HDFC Bank',
    ),
  ];
}
