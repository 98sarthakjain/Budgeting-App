import 'package:flutter/foundation.dart';

/// Central service for managing the app's base currency and formatting amounts.
///
/// This is intentionally simple for now: it does **not** do FX conversion.
/// Whatever numeric value you pass in is assumed to already be in the current
/// base currency units – we only add symbol, code and handle decimals.
class AppCurrencyService extends ChangeNotifier {
  AppCurrencyService._internal();
  static final AppCurrencyService instance = AppCurrencyService._internal();

  // Supported currency codes.
  static const String _inr = 'INR';
  static const String _dkk = 'DKK';
  static const String _jpy = 'JPY';

  String _baseCode = _inr;

  /// Current base ISO code, e.g. 'INR', 'DKK', 'JPY'.
  String get baseCode => _baseCode;

  /// Current currency symbol matching [baseCode].
  String get baseSymbol {
    switch (_baseCode) {
      case _inr:
        return '₹';
      case _dkk:
        return 'kr';
      case _jpy:
        return '¥';
      default:
        return '';
    }
  }

  /// Change the app-wide base currency.
  ///
  /// Unknown codes fall back to INR.
  void setBaseCurrency(String currencyCode) {
    final upper = currencyCode.toUpperCase();
    if (upper == _baseCode) return;

    switch (upper) {
      case _inr:
      case _dkk:
      case _jpy:
        _baseCode = upper;
        break;
      default:
        _baseCode = _inr;
        break;
    }
    notifyListeners();
  }

  /// Format an amount that is already expressed in the current base currency.
  ///
  /// Example: if [baseCode] is 'INR', `formatBase(1234.5)` -> `₹ 1234.50`.
  /// JPY is formatted without decimals.
  String formatBase(double amount, {bool withCode = false}) {
    final decimals = (_baseCode == _jpy) ? 0 : 2;
    final fixed = amount.toStringAsFixed(decimals);
    final result = '$baseSymbol $fixed';
    return withCode ? '$result $baseCode' : result;
  }

  /// Convenience alias used by some widgets.
  String format(double amount, {bool withCode = false}) =>
      formatBase(amount, withCode: withCode);
}
