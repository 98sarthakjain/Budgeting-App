// lib/core/design/currency.dart

import '../services/app_currency_service.dart';

class AppCurrency {
  /// Current symbol and code are always taken from the service base.
  static String get symbol => AppCurrencyService.instance.baseSymbol;
  static String get code => AppCurrencyService.instance.baseCode;

  /// Change the app-wide base currency.
  ///
  /// Example:
  ///   AppCurrency.setCurrency('INR');
  ///   AppCurrency.setCurrency('DKK');
  ///   AppCurrency.setCurrency('JPY');
  static void setCurrency(String currencyCode) {
    AppCurrencyService.instance.setBaseCurrency(currencyCode);
  }

  /// Format an amount in the current base currency.
  static String format(double amount, {bool withCode = false}) {
    return AppCurrencyService.instance.formatBase(amount, withCode: withCode);
  }
}
