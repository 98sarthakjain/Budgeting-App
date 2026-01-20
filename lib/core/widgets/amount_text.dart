import 'package:flutter/material.dart';
import 'package:budgeting_app/core/services/app_currency_service.dart';

class AmountText extends StatelessWidget {
  final double amountInInr;
  final bool isExpense;

  const AmountText({
    super.key,
    required this.amountInInr,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    final service = AppCurrencyService.instance;
    final formatted = service.format(amountInInr);

    final color = isExpense ? Colors.red.shade600 : Colors.green.shade600;

    return Text(
      formatted,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: color,
      ),
      textAlign: TextAlign.right,
    );
  }
}
