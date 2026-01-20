// lib/features/cards/domain/credit_card.dart
import 'package:flutter/foundation.dart';

@immutable
class CardFace {
  final String id;
  final String scheme; // e.g. "Mastercard", "Amex"
  final String last4; // last 4 digits displayed on UI

  const CardFace({required this.id, required this.scheme, required this.last4});

  CardFace copyWith({String? scheme, String? last4}) {
    return CardFace(
      id: id,
      scheme: scheme ?? this.scheme,
      last4: last4 ?? this.last4,
    );
  }
}

@immutable
class CreditCard {
  final String id;

  /// Nickname shown in UI, e.g. "Amazon ICICI", "HDFC Millennia 2395"
  final String nickname;

  /// Name printed on card, shown in UI in uppercase.
  final String holderName;

  /// Bank, e.g. "ICICI Bank", "HDFC Bank".
  final String bankName;

  /// Total credit limit in base currency.
  final double creditLimit;

  /// Billing cycle anchor day 1–31 (e.g. 10 = statement every 10th).
  final int billingDay;

  /// Payment due day 1–31.
  final int dueDay;

  /// Annual fee (0 if lifetime free).
  final double annualFee;

  /// Short cashback summary for human memory.
  final String cashbackSummary;

  /// Whether this card is closed (no further transactions).
  final bool isClosed;

  /// Optional closed timestamp.
  final DateTime? closedAt;

  /// One or more physical faces (e.g. Mastercard + Amex).
  final List<CardFace> faces;

  const CreditCard({
    required this.id,
    required this.nickname,
    required this.holderName,
    required this.bankName,
    required this.creditLimit,
    required this.billingDay,
    required this.dueDay,
    required this.annualFee,
    required this.cashbackSummary,
    this.isClosed = false,
    this.closedAt,
    this.faces = const [],
  });

  CardFace? get primaryFace => faces.isNotEmpty ? faces.first : null;

  CreditCard copyWith({
    String? nickname,
    String? holderName,
    String? bankName,
    double? creditLimit,
    int? billingDay,
    int? dueDay,
    double? annualFee,
    String? cashbackSummary,
    bool? isClosed,
    DateTime? closedAt,
    List<CardFace>? faces,
  }) {
    return CreditCard(
      id: id,
      nickname: nickname ?? this.nickname,
      holderName: holderName ?? this.holderName,
      bankName: bankName ?? this.bankName,
      creditLimit: creditLimit ?? this.creditLimit,
      billingDay: billingDay ?? this.billingDay,
      dueDay: dueDay ?? this.dueDay,
      annualFee: annualFee ?? this.annualFee,
      cashbackSummary: cashbackSummary ?? this.cashbackSummary,
      isClosed: isClosed ?? this.isClosed,
      closedAt: closedAt ?? this.closedAt,
      faces: faces ?? this.faces,
    );
  }
}
