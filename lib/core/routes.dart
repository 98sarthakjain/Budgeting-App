import 'package:flutter/material.dart';

// Home
import 'package:budgeting_app/features/home/presentation/home_screen.dart';

// Transactions
import 'package:budgeting_app/features/transactions/presentation/add_transaction_screen.dart';
import 'package:budgeting_app/features/transactions/data/in_memory_transaction_repository.dart';

// Credit Cards
import 'package:budgeting_app/features/cards/domain/credit_card.dart';
import 'package:budgeting_app/features/cards/data/in_memory_card_repository.dart';
import 'package:budgeting_app/features/cards/presentation/credit_cards_screen.dart';
import 'package:budgeting_app/features/cards/presentation/add_card_screen.dart';
import 'package:budgeting_app/features/cards/presentation/credit_card_detail_screen.dart';

// Savings
import 'package:budgeting_app/features/savings/presentation/savings_accounts_screen.dart';
import 'package:budgeting_app/features/savings/presentation/savings_account_detail_screen.dart';
import 'package:budgeting_app/features/savings/data/in_memory_savings_account_repository.dart';

// Cash
import 'package:budgeting_app/features/cash/presentation/cash_accounts_screen.dart';
import 'package:budgeting_app/features/cash/presentation/cash_account_detail_screen.dart';
import 'package:budgeting_app/features/cash/data/in_memory_cash_account_repository.dart';

// Insurance
import 'package:budgeting_app/features/insurance/presentation/insurance_list_screen.dart';
import 'package:budgeting_app/features/insurance/presentation/insurance_detail_screen.dart';
import 'package:budgeting_app/features/insurance/data/in_memory_insurance_repository.dart';

// Investments
import 'package:budgeting_app/features/investments/presentation/investments_dashboard_screen.dart';
import 'package:budgeting_app/features/investments/presentation/investment_detail_screen.dart';
import 'package:budgeting_app/features/investments/presentation/investment_category_screen.dart';
import 'package:budgeting_app/features/investments/data/in_memory_investment_repository.dart';

// Loans
import 'package:budgeting_app/features/loans/presentation/loan_accounts_screen.dart';
import 'package:budgeting_app/features/loans/presentation/loan_account_detail_screen.dart';
import 'package:budgeting_app/features/loans/presentation/loan_prepayment_planner_screen.dart';
import 'package:budgeting_app/features/loans/data/in_memory_loan_account_repository.dart';

/// Single in-memory transaction repository instance used across the app.
final _transactionRepository = InMemoryTransactionRepository();

/// Single in-memory card repository instance for credit cards.
final _cardRepository = InMemoryCardRepository();

/// Single in-memory savings repository instance.
final _savingsRepository = InMemorySavingsAccountRepository();

/// Single in-memory cash repository instance.
final _cashRepository = InMemoryCashAccountRepository();

class AppRoutes {
  // Core
  static const home = '/';
  static const addTransaction = '/add-transaction';

  // Credit Cards
  static const manageCards = '/manage-cards';
  static const addCard = '/add-card';
  static const creditCards = '/credit-cards';
  static const creditCardDetail = '/credit-card-detail';

  // Savings
  static const savingsAccounts = '/savings-accounts';
  static const savingsAccountDetail = '/savings-account-detail';

  // Cash
  static const cashAccounts = '/cash-accounts';
  static const cashAccountDetail = '/cash-account-detail';

  // Insurance
  static const insuranceList = '/insurance-list';
  static const insuranceDetail = '/insurance-detail';

  // Investments
  static const investmentsDashboard = '/investments-dashboard';
  static const investmentCategory = '/investment-category';
  static const investmentDetail = '/investment-detail';

  // Loans
  static const loans = '/loans';
  static const loanDetail = '/loan-detail';
  static const loanPrepayment = '/loan-prepayment';
}

/// Global routes map used by MaterialApp.routes
final Map<String, WidgetBuilder> appRoutes = {
  // Home
  AppRoutes.home: (_) => HomeScreen(
        transactionRepository: _transactionRepository,
        savingsRepository: _savingsRepository,
        cashRepository: _cashRepository,
        cardRepository: _cardRepository,
      ),

  // Transactions
  AppRoutes.addTransaction: (_) => AddTransactionScreen(
        transactionRepository: _transactionRepository,
        savingsRepository: _savingsRepository,
        cashRepository: _cashRepository,
        cardRepository: _cardRepository,
      ),

  // Credit Cards
  AppRoutes.addCard: (_) => AddCardScreen(
    repository: _cardRepository,
    transactionRepository: _transactionRepository,
  ),
  AppRoutes.creditCards: (_) => CreditCardsScreen(
    repository: _cardRepository,
    transactionRepository: _transactionRepository,
  ),

  // ⬇️ UPDATED: detail route now expects a CreditCard object as argument
  AppRoutes.creditCardDetail: (context) {
    final card = ModalRoute.of(context)!.settings.arguments as CreditCard;
    return CreditCardDetailScreen(
      card: card,
      transactionRepository: _transactionRepository,
    );
  },

  // Savings
  AppRoutes.savingsAccounts: (_) => SavingsAccountsScreen(
    repository: _savingsRepository,
    transactionRepository: _transactionRepository,
  ),
  AppRoutes.savingsAccountDetail: (context) {
    final account = ModalRoute.of(context)!.settings.arguments as dynamic;
    return SavingsAccountDetailScreen(
      account: account,
      repository: _savingsRepository,
      transactionRepository: _transactionRepository,
    );
  },

  // Cash
  AppRoutes.cashAccounts: (_) => CashAccountsScreen(
    repository: _cashRepository,
    transactionRepository: _transactionRepository,
  ),
  AppRoutes.cashAccountDetail: (context) {
    final account = ModalRoute.of(context)!.settings.arguments as dynamic;
    return CashAccountDetailScreen(
      account: account,
      transactionRepository: _transactionRepository,
    );
  },

  // Insurance
  AppRoutes.insuranceList: (_) =>
      InsuranceListScreen(repository: InMemoryInsuranceRepository()),
  AppRoutes.insuranceDetail: (context) {
    final policy = ModalRoute.of(context)!.settings.arguments as dynamic;
    return InsuranceDetailScreen(policy: policy);
  },

  // Investments
  AppRoutes.investmentsDashboard: (_) =>
      InvestmentsDashboardScreen(repository: InMemoryInvestmentRepository()),
  AppRoutes.investmentCategory: (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return InvestmentCategoryScreen(
      type: args['type'],
      repository: InMemoryInvestmentRepository(),
    );
  },
  AppRoutes.investmentDetail: (context) {
    final account = ModalRoute.of(context)!.settings.arguments as dynamic;
    return InvestmentDetailScreen(account: account);
  },

  // Loans
  AppRoutes.loans: (_) =>
      LoanAccountsScreen(repository: InMemoryLoanAccountRepository()),
  AppRoutes.loanDetail: (context) {
    final loan = ModalRoute.of(context)!.settings.arguments as dynamic;
    return LoanAccountDetailScreen(loan: loan);
  },
  AppRoutes.loanPrepayment: (context) {
    final loan = ModalRoute.of(context)!.settings.arguments as dynamic;
    return LoanPrepaymentPlannerScreen(loan: loan);
  },
};
