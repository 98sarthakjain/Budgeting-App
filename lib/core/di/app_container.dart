import 'package:hive_flutter/hive_flutter.dart';

import 'package:budgeting_app/features/cards/data/card_repository.dart';
import 'package:budgeting_app/features/cards/data/hive_card_repository.dart';
import 'package:budgeting_app/features/cash/data/cash_account_repository.dart';
import 'package:budgeting_app/features/cash/data/hive_cash_account_repository.dart';
import 'package:budgeting_app/features/savings/data/savings_account_repository.dart';
import 'package:budgeting_app/features/savings/data/hive_savings_account_repository.dart';
import 'package:budgeting_app/features/transactions/data/hive_transaction_repository.dart';
import 'package:budgeting_app/features/transactions/data/transaction_repository.dart';

/// Minimal app-wide container (DI/service locator) for v1.
///
/// Purpose:
/// - Own Hive initialization and box opening.
/// - Provide singletons used across routes/screens.
///
/// We keep it intentionally small and explicit so it stays easy to reason about.
class AppContainer {
  static late final TransactionRepository transactions;
  static late final CashAccountRepository cash;
  static late final SavingsAccountRepository savings;
  static late final CardRepository cards;

  // Box names (stable storage contract).
  static const String _boxTxns = 'txns_v1';
  static const String _boxCash = 'cash_accounts_v1';
  static const String _boxSavings = 'savings_accounts_v1';
  static const String _boxCards = 'credit_cards_v1';

  static Future<void> init() async {
    await Hive.initFlutter();

    final txBox = await Hive.openBox(_boxTxns);
    final cashBox = await Hive.openBox(_boxCash);
    final savingsBox = await Hive.openBox(_boxSavings);
    final cardsBox = await Hive.openBox(_boxCards);

    transactions = HiveTransactionRepository(txBox);
    cash = HiveCashAccountRepository(cashBox);
    savings = HiveSavingsAccountRepository(savingsBox);
    cards = HiveCardRepository(cardsBox);
  }
}
