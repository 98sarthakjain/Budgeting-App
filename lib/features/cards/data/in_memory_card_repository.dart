// lib/features/cards/data/in_memory_card_repository.dart
import 'dart:async';

import 'package:budgeting_app/features/cards/data/card_repository.dart';
import 'package:budgeting_app/features/cards/domain/credit_card.dart';

class InMemoryCardRepository implements CardRepository {
  final List<CreditCard> _cards = [];
  final StreamController<List<CreditCard>> _controller =
      StreamController<List<CreditCard>>.broadcast();

  InMemoryCardRepository({List<CreditCard>? seed}) {
    if (seed != null) {
      _cards.addAll(seed);
    }
    _emit();
  }

  void _emit() {
    _controller.add(List.unmodifiable(_cards));
  }

  @override
  Stream<List<CreditCard>> watchAllCards({bool includeClosed = false}) {
    final out = StreamController<List<CreditCard>>();

    void push(List<CreditCard> all) {
      final filtered = includeClosed
          ? all
          : all.where((c) => !c.isClosed).toList(growable: false);
      out.add(List.unmodifiable(filtered));
    }

    // Initial snapshot
    push(_cards);

    final sub = _controller.stream.listen(push);
    out.onCancel = () => sub.cancel();

    return out.stream;
  }

  @override
  Future<List<CreditCard>> getAllCards({bool includeClosed = false}) async {
    if (includeClosed) return List.unmodifiable(_cards);
    return List.unmodifiable(_cards.where((c) => !c.isClosed));
  }

  @override
  Future<CreditCard?> getById(String id) async {
    try {
      return _cards.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> upsertCard(CreditCard card) async {
    final index = _cards.indexWhere((c) => c.id == card.id);
    if (index == -1) {
      _cards.add(card);
    } else {
      _cards[index] = card;
    }
    _emit();
  }

  @override
  Future<void> deleteCard(String id) async {
    _cards.removeWhere((c) => c.id == id);
    _emit();
  }
}
