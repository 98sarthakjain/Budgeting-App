// lib/features/cards/domain/card_face.dart
import 'package:flutter/foundation.dart';

/// One physical plastic under a credit-card account.
/// Example: ICICI Sapphiro → 1 Mastercard + 1 Amex face, same statement.
@immutable
class CardFace {
  /// Local id for the face within a card, e.g. "mastercard", "amex", "primary".
  final String id;

  /// Network name, e.g. "Visa", "Mastercard", "Amex", "RuPay", "Other".
  final String network;

  /// Last 4 digits printed on this physical card.
  final String last4;

  const CardFace({
    required this.id,
    required this.network,
    required this.last4,
  });

  CardFace copyWith({String? id, String? network, String? last4}) {
    return CardFace(
      id: id ?? this.id,
      network: network ?? this.network,
      last4: last4 ?? this.last4,
    );
  }
}
