class CardInfo {
  final String id;
  final String name; // e.g. "HDFC Regalia"
  final String bank; // e.g. "HDFC"
  final double creditLimit;

  /// Billing cycle anchor day 1–31 (e.g. 10 = statement generated every 10th).
  final int billingDay;

  /// Due date anchor day 1–31 (e.g. 20 = payment due every 20th).
  final int dueDay;

  /// Annual fee in base currency (0 if lifetime free).
  final double annualFee;

  /// Short human-readable cashback description, e.g.
  /// "5% on Amazon, 1.5% on others, max ₹1500/qtr".
  final String cashbackSummary;

  const CardInfo({
    required this.id,
    required this.name,
    required this.bank,
    required this.creditLimit,
    required this.billingDay,
    required this.dueDay,
    required this.annualFee,
    required this.cashbackSummary,
  });
}
