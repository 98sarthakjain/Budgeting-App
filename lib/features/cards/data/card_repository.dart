// lib/features/cards/data/card_repository.dart
import 'package:budgeting_app/features/cards/domain/credit_card.dart';

abstract class CardRepository {
  /// Stream of cards; optionally includes closed cards.
  Stream<List<CreditCard>> watchAllCards({bool includeClosed = false});

  /// One-shot fetch; optionally includes closed cards.
  Future<List<CreditCard>> getAllCards({bool includeClosed = false});

  Future<CreditCard?> getById(String id);

  /// Insert or update based on id.
  Future<void> upsertCard(CreditCard card);

  Future<void> deleteCard(String id);
}
