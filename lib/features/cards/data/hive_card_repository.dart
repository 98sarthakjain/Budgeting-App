// lib/features/cards/data/hive_card_repository.dart
import 'dart:async';
import 'package:hive/hive.dart';

import 'package:budgeting_app/features/cards/data/card_repository.dart';
import 'package:budgeting_app/features/cards/domain/credit_card.dart';

class HiveCardRepository implements CardRepository {
  final Box<CreditCard> _box;

  HiveCardRepository(this._box);

  @override
  Stream<List<CreditCard>> watchAllCards({bool includeClosed = false}) async* {
    List<CreditCard> filter(Iterable<CreditCard> all) {
      return List.unmodifiable(
        includeClosed ? all : all.where((c) => !c.isClosed),
      );
    }

    yield filter(_box.values);

    yield* _box.watch().map((_) => filter(_box.values));
  }

  @override
  Future<List<CreditCard>> getAllCards({bool includeClosed = false}) async {
    final all = _box.values.toList();
    if (includeClosed) return all;
    return all.where((c) => !c.isClosed).toList(growable: false);
  }

  @override
  Future<CreditCard?> getById(String id) async {
    return _box.get(id);
  }

  @override
  Future<void> upsertCard(CreditCard card) async {
    await _box.put(card.id, card);
  }

  @override
  Future<void> deleteCard(String id) async {
    await _box.delete(id);
  }
}
