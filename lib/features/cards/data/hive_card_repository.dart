// lib/features/cards/data/hive_card_repository.dart
import 'dart:async';

import 'package:hive/hive.dart';

import 'package:budgeting_app/features/cards/data/card_repository.dart';
import 'package:budgeting_app/features/cards/domain/credit_card.dart';

/// Hive-backed card repository.
///
/// We store plain Maps in Hive (instead of Hive TypeAdapters) to keep schema
/// evolution simple for a fast-moving v1.
class HiveCardRepository implements CardRepository {
  final Box _box;

  HiveCardRepository(this._box);

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> _faceToMap(CardFace f) => {
        'id': f.id,
        'scheme': f.scheme,
        'last4': f.last4,
      };

  static CardFace _faceFromMap(Map m) => CardFace(
        id: (m['id'] ?? '').toString(),
        scheme: (m['scheme'] ?? '').toString(),
        last4: (m['last4'] ?? '').toString(),
      );

  static Map<String, dynamic> _cardToMap(CreditCard c) => {
        'id': c.id,
        'nickname': c.nickname,
        'holderName': c.holderName,
        'bankName': c.bankName,
        'creditLimit': c.creditLimit,
        'billingDay': c.billingDay,
        'dueDay': c.dueDay,
        'annualFee': c.annualFee,
        'cashbackSummary': c.cashbackSummary,
        'isClosed': c.isClosed,
        'closedAt': c.closedAt?.millisecondsSinceEpoch,
        'faces': c.faces.map(_faceToMap).toList(growable: false),
      };

  static CreditCard _cardFromMap(Map m) {
    final facesRaw = m['faces'];
    final faces = facesRaw is List
        ? facesRaw
            .whereType<Map>()
            .map(_faceFromMap)
            .toList(growable: false)
        : const <CardFace>[];

    return CreditCard(
      id: (m['id'] ?? '').toString(),
      nickname: (m['nickname'] ?? '').toString(),
      holderName: (m['holderName'] ?? '').toString(),
      bankName: (m['bankName'] ?? '').toString(),
      creditLimit: (m['creditLimit'] is num) ? (m['creditLimit'] as num).toDouble() : 0.0,
      billingDay: (m['billingDay'] is num) ? (m['billingDay'] as num).toInt() : 1,
      dueDay: (m['dueDay'] is num) ? (m['dueDay'] as num).toInt() : 1,
      annualFee: (m['annualFee'] is num) ? (m['annualFee'] as num).toDouble() : 0.0,
      cashbackSummary: (m['cashbackSummary'] ?? '').toString(),
      isClosed: m['isClosed'] == true,
      closedAt: m['closedAt'] is num
          ? DateTime.fromMillisecondsSinceEpoch((m['closedAt'] as num).toInt())
          : null,
      faces: faces,
    );
  }

  List<CreditCard> _all({required bool includeClosed}) {
    final raw = _box.values;
    final all = raw
        .whereType<Map>()
        .map(_cardFromMap)
        .toList(growable: false);

    if (includeClosed) return all;
    return all.where((c) => !c.isClosed).toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // API
  // ---------------------------------------------------------------------------

  @override
  Stream<List<CreditCard>> watchAllCards({bool includeClosed = false}) async* {
    yield _all(includeClosed: includeClosed);
    yield* _box.watch().map((_) => _all(includeClosed: includeClosed));
  }

  @override
  Future<List<CreditCard>> getAllCards({bool includeClosed = false}) async {
    return _all(includeClosed: includeClosed);
  }

  @override
  Future<CreditCard?> getById(String id) async {
    final raw = _box.get(id);
    if (raw is! Map) return null;
    return _cardFromMap(raw);
  }

  @override
  Future<void> upsertCard(CreditCard card) async {
    await _box.put(card.id, _cardToMap(card));
  }

  @override
  Future<void> deleteCard(String id) async {
    await _box.delete(id);
  }
}
