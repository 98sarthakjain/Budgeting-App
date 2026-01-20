// lib/core/services/card_store.dart
import 'package:flutter/foundation.dart';
import 'package:budgeting_app/features/cards/domain/credit_card.dart';

/// Legacy in-memory store for credit cards.
/// Now mainly used as a simple list holder for UI helpers.
/// Balances/outstanding should come from the TransactionRepository, not here.
class CardStore extends ChangeNotifier {
  CardStore._internal();
  static final CardStore instance = CardStore._internal();

  final List<CreditCard> _cards = [];

  List<CreditCard> get cards => List.unmodifiable(_cards);

  bool get hasCards => _cards.isNotEmpty;

  void addCard(CreditCard card) {
    final index = _cards.indexWhere((c) => c.id == card.id);
    if (index == -1) {
      _cards.add(card);
    } else {
      _cards[index] = card;
    }
    notifyListeners();
  }

  void clear() {
    _cards.clear();
    notifyListeners();
  }

  CreditCard? getById(String id) {
    try {
      return _cards.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Kept only for backwards compatibility – currently a no-op.
  void applyOutstandingDelta(String cardId, double delta) {
    // Intentionally empty – outstanding is derived from transactions now.
  }

  /// Total outstanding from this store. For now, this is just 0;
  /// in future it can be wired to a ledger summary if needed.
  double get totalOutstanding => 0.0;
}
