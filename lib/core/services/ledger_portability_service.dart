import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:budgeting_app/features/cards/data/card_repository.dart';
import 'package:budgeting_app/features/cards/domain/credit_card.dart';
import 'package:budgeting_app/features/cash/data/cash_account_repository.dart';
import 'package:budgeting_app/features/cash/domain/cash_account.dart';
import 'package:budgeting_app/features/savings/data/savings_account_repository.dart';
import 'package:budgeting_app/features/savings/domain/savings_account.dart';
import 'package:budgeting_app/features/transactions/data/transaction_repository.dart';
import 'package:budgeting_app/features/transactions/domain/transaction.dart';

/// Lightweight, dependency-free (no file picker) backup/export + import.
///
/// Goal: during early testing (crashes/resets), you can copy a JSON backup to
/// Notes/Drive, and later paste it back to restore.
///
/// This is intentionally simple and deterministic:
/// - Export produces a versioned JSON snapshot.
/// - Import defaults to **replace** (wipe existing data then re-create).
/// - IDs are not preserved for transactions (repository generates new IDs).
///   Accounts/cards preserve IDs if repositories accept them.
class LedgerPortabilityService {
  static const int currentSchemaVersion = 1;

  final SavingsAccountRepository savingsRepository;
  final CashAccountRepository cashRepository;
  final CardRepository cardRepository;
  final TransactionRepository transactionRepository;

  const LedgerPortabilityService({
    required this.savingsRepository,
    required this.cashRepository,
    required this.cardRepository,
    required this.transactionRepository,
  });

  // ---------------------------------------------------------------------------
  // Back-compat wrappers (UI calls these names)
  // ---------------------------------------------------------------------------

  /// Back-compat alias used by DataToolsScreen.
  Future<String> exportBackupJson() => exportJson();

  /// Back-compat alias used by DataToolsScreen.
  Future<void> importBackupJson(String json, {bool replace = true}) =>
      importJson(json, replace: replace);

  /// Adds a small dataset for quick UI testing.
  ///
  /// This is intentionally tiny and deterministic.
  Future<void> seedSampleData() async {
    // Replace (wipe) first to avoid duplicating data.
    await resetAllData();

    final now = DateTime.now();

    final salary = SavingsAccount(
      id: 'sav-sample-salary',
      bankName: 'HDFC Bank',
      accountNickname: 'Salary Account',
      accountType: 'Savings',
      maskedAccountNumber: 'XXXX 1234',
      ifsc: 'HDFC0000001',
      branchName: 'Sample Branch',
      currentBalance: 0,
      availableBalance: 0,
      interestRate: 3.0,
      minBalanceRequired: 0,
      isSalaryAccount: true,
      hasNominee: true,
      lastInterestCreditedOn: now,
      lastInterestAmount: 0,
    );
    await savingsRepository.createAccount(salary);

    // Cash in hand is protected and always exists.
    final cash = await cashRepository.getCashAccount();
    await cashRepository.overrideBalance(accountId: cash.id, newBalance: 2000);

    final wallet = CashAccount(
      id: 'wallet-sample-upi',
      name: 'UPI Wallet',
      balance: 500,
    );
    await cashRepository.createWallet(wallet);

    final card = CreditCard(
      id: 'card-sample-icici',
      nickname: 'Amazon ICICI',
      holderName: 'You',
      bankName: 'ICICI Bank',
      creditLimit: 100000,
      billingDay: 10,
      dueDay: 25,
      annualFee: 0,
      cashbackSummary: '1–5% cashback',
      faces: const [CardFace(id: 'face-1', scheme: 'VISA', last4: '9876')],
    );
    await cardRepository.upsertCard(card);

    await transactionRepository.createOpeningBalance(
      accountId: salary.id,
      amount: 50000,
      bookingDate: now,
      description: 'Opening balance',
    );
    await transactionRepository.createIncome(
      accountId: salary.id,
      amount: 80000,
      bookingDate: now,
      categoryId: 'Salary',
      description: 'Salary',
      tags: const ['sample'],
    );
    await transactionRepository.createExpense(
      accountId: salary.id,
      amount: 1200,
      bookingDate: now,
      categoryId: 'Food',
      description: 'Lunch',
      tags: const ['sample'],
    );
    await transactionRepository.createTransfer(
      fromAccountId: salary.id,
      toAccountId: cash.id,
      amount: 3000,
      bookingDate: now,
      description: 'ATM withdrawal',
    );
  }

  Future<String> exportJson() async {
    final savings = await savingsRepository.getAllAccounts();
    final cash = await cashRepository.getAllAccounts();
    final cards = await cardRepository.getAllCards();
    final txns = await transactionRepository.query();

    txns.sort((a, b) => a.bookingDate.compareTo(b.bookingDate));

    final payload = <String, dynamic>{
      'schemaVersion': currentSchemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'savingsAccounts': savings.map(_savingsToJson).toList(growable: false),
      'cashAccounts': cash.map(_cashToJson).toList(growable: false),
      'creditCards': cards.map(_cardToJson).toList(growable: false),
      'transactions': txns.map(_txnToJson).toList(growable: false),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<void> copyExportToClipboard() async {
    final json = await exportJson();
    await Clipboard.setData(ClipboardData(text: json));
  }

  Future<void> resetAllData() async {
    // Delete transactions first (so account balances don't matter).
    final allTxns = await transactionRepository.query();
    for (final t in allTxns) {
      await transactionRepository.deleteTransaction(t.id);
    }

    final cards = await cardRepository.getAllCards();
    for (final c in cards) {
      await cardRepository.deleteCard(c.id);
    }

    final cash = await cashRepository.getAllAccounts();
    // Cash repo always has a protected "cash in hand" account.
    // We wipe wallets and reset cash balance to 0.
    for (final a in cash) {
      if (a.id == 'cash-in-hand') {
        await cashRepository.overrideBalance(accountId: a.id, newBalance: 0);
      } else {
        await cashRepository.deleteWallet(a.id);
      }
    }

    final savings = await savingsRepository.getAllAccounts();
    for (final a in savings) {
      await savingsRepository.deleteAccount(a.id);
    }
  }

  /// Import a JSON backup.
  ///
  /// By default, this **replaces** all existing data.
  Future<void> importJson(String json, {bool replace = true}) async {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid JSON backup: root is not an object');
    }

    final schemaVersion = decoded['schemaVersion'];
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException(
        'Unsupported backup schemaVersion: $schemaVersion (expected $currentSchemaVersion)',
      );
    }

    if (replace) {
      await resetAllData();
    }

    final savings = _asList(decoded['savingsAccounts']);
    final cash = _asList(decoded['cashAccounts']);
    final cards = _asList(decoded['creditCards']);
    final txns = _asList(decoded['transactions']);

    for (final item in savings) {
      final a = _savingsFromJson(item);
      await savingsRepository.createAccount(a);
    }
    for (final item in cash) {
      final a = _cashFromJson(item);
      if (a.id == 'cash-in-hand') {
        // Ensure the protected cash account exists, then apply snapshot.
        final cashAcc = await cashRepository.getCashAccount();
        if (a.name != cashAcc.name) {
          await cashRepository.updateWallet(cashAcc.copyWith(name: a.name));
        }
        await cashRepository.overrideBalance(
          accountId: cashAcc.id,
          newBalance: a.balance,
        );
      } else {
        await cashRepository.createWallet(a);
      }
    }
    for (final item in cards) {
      final c = _cardFromJson(item);
      await cardRepository.upsertCard(c);
    }

    // Transactions: create via repository helpers (new IDs) but preserve values.
    for (final item in txns) {
      final t = _txnFromJson(item);
      switch (t.type) {
        case TransactionType.income:
          await transactionRepository.createIncome(
            accountId: t.accountId,
            amount: t.amount,
            categoryId: t.categoryId,
            bookingDate: t.bookingDate,
            description: t.description,
            tags: t.tags,
          );
          break;
        case TransactionType.expense:
          await transactionRepository.createExpense(
            accountId: t.accountId,
            amount: t.amount,
            categoryId: t.categoryId,
            bookingDate: t.bookingDate,
            description: t.description,
            tags: t.tags,
          );
          break;
        case TransactionType.openingBalance:
          await transactionRepository.createOpeningBalance(
            accountId: t.accountId,
            amount: t.amount,
            bookingDate: t.bookingDate,
            description: t.description,
          );
          break;
        case TransactionType.transferIn:
        case TransactionType.transferOut:
          // We export both sides, but on import we only need to create a single
          // transfer. We'll create it once when we see the transferOut side.
          if (t.type == TransactionType.transferOut &&
              t.counterAccountId != null) {
            await transactionRepository.createTransfer(
              fromAccountId: t.accountId,
              toAccountId: t.counterAccountId!,
              amount: t.amount,
              bookingDate: t.bookingDate,
              description: t.description,
              notes: _notesFromTags(t.tags, existing: t.notes),
            );
          }
          break;
        case TransactionType.adjustment:
          final direction = t.adjustmentDirection ??
              (t.amount >= 0
                  ? AdjustmentDirection.increase
                  : AdjustmentDirection.decrease);
          await transactionRepository.createAdjustment(
            accountId: t.accountId,
            amount: t.amount.abs(),
            direction: direction,
            bookingDate: t.bookingDate,
            description: t.description,
            notes: _notesFromTags(t.tags, existing: t.notes),
          );
          break;
      }
    }
  }

  /// A simple CSV template you can paste into a Google Sheet.
  ///
  /// Import supports record types:
  /// - SAVINGS, CASH, CARD, TXN
  ///
  /// Notes:
  /// - For CARD openingBalance, use a negative number to represent amount due.
  /// - TXN.kind: income | expense | opening | transfer
  /// - TXN uses accountKey/fromKey/toKey to reference accounts by key.
  static String csvTemplate() {
    return [
      'recordType,key,name,bank,numberLast4,openingBalance,date,kind,amount,accountKey,fromKey,toKey,category,description,tags',
      // Accounts
      'SAVINGS,SAV-EMERGENCY,Emergency Fund,HDFC,1234,50000,2026-01-01,,,,,,,,',
      'CASH,CASH-HAND,Cash in Hand,,,	2000,2026-01-01,,,,,,,,',
      'CARD,CARD-AMAZON,Amazon Pay ICICI,ICICI,9876,-12000,2026-01-01,,,,,,,,',
      // Transactions
      'TXN,,,,,,2026-01-05,income,8000,SAV-EMERGENCY,,,Salary,January Salary,"salary,jan"',
      'TXN,,,,,,2026-01-06,expense,500,SAV-EMERGENCY,,,Food,Lunch,"food"',
      'TXN,,,,,,2026-01-07,transfer,1500,,SAV-EMERGENCY,CASH-HAND,,ATM Withdrawal,"transfer"',
      'TXN,,,,,,2026-01-08,transfer,2000,,SAV-EMERGENCY,CARD-AMAZON,,Card Payment,"card,payment"',
    ].join('\n');
  }

  /// Import CSV that matches [csvTemplate]. Defaults to replace.
  Future<void> importCsv(String csv, {bool replace = true}) async {
    final rows = const LineSplitter().convert(csv.trim());
    if (rows.isEmpty) return;

    // Basic CSV split (good enough for our controlled template).
    // If the user adds commas inside values, they should wrap the cell in quotes.
    List<String> splitRow(String row) {
      final out = <String>[];
      final buf = StringBuffer();
      bool inQuotes = false;
      for (int i = 0; i < row.length; i++) {
        final ch = row[i];
        if (ch == '"') {
          inQuotes = !inQuotes;
          continue;
        }
        if (ch == ',' && !inQuotes) {
          out.add(buf.toString());
          buf.clear();
          continue;
        }
        buf.write(ch);
      }
      out.add(buf.toString());
      return out.map((e) => e.trim()).toList(growable: false);
    }

    final header = splitRow(rows.first);
    final idx = <String, int>{
      for (int i = 0; i < header.length; i++) header[i]: i,
    };

    String cell(List<String> cols, String name) {
      final i = idx[name];
      if (i == null || i >= cols.length) return '';
      return cols[i];
    }

    if (replace) {
      await resetAllData();
    }

    // Map account keys to IDs so TXNs can reference them.
    final keyToId = <String, String>{};

    // First pass: create accounts/cards.
    for (final row in rows.skip(1)) {
      if (row.trim().isEmpty) continue;
      final cols = splitRow(row);
      final recordType = cell(cols, 'recordType').toUpperCase();
      final key = cell(cols, 'key');
      final name = cell(cols, 'name');
      final bank = cell(cols, 'bank');
      final last4 = cell(cols, 'numberLast4');
      final openingStr = cell(cols, 'openingBalance');
      final dateStr = cell(cols, 'date');
      final opening = double.tryParse(openingStr.replaceAll('\t', '').trim()) ?? 0.0;
      final date = DateTime.tryParse(dateStr) ?? DateTime.now();

      if (recordType == 'SAVINGS') {
        final a = SavingsAccount(
          id: _stableIdFromKey('sav', key),
          bankName: bank.isEmpty ? 'Bank' : bank,
          accountNickname: name.isEmpty ? 'Savings' : name,
          accountType: 'Savings',
          maskedAccountNumber: last4.isEmpty ? 'XXXX' : 'XXXX $last4',
          ifsc: '',
          branchName: '',
          currentBalance: 0,
          availableBalance: 0,
          interestRate: 0,
          minBalanceRequired: 0,
          isSalaryAccount: false,
          hasNominee: false,
          lastInterestCreditedOn: DateTime.now(),
          lastInterestAmount: 0,
        );
        await savingsRepository.createAccount(a);
        keyToId[key] = a.id;
        if (opening != 0) {
          await transactionRepository.createOpeningBalance(
            accountId: a.id,
            amount: opening,
            bookingDate: date,
            description: 'Opening balance',
          );
        }
      } else if (recordType == 'CASH') {
        // Special handling for "Cash in hand".
        final isCashInHand =
            key.toUpperCase() == 'CASH-HAND' || key.toLowerCase() == 'cash';
        if (isCashInHand) {
          final cashAcc = await cashRepository.getCashAccount();
          keyToId[key] = cashAcc.id;
          if (name.isNotEmpty && name != cashAcc.name) {
            await cashRepository.updateWallet(cashAcc.copyWith(name: name));
          }
          if (opening != 0) {
            await cashRepository.overrideBalance(
              accountId: cashAcc.id,
              newBalance: opening,
            );
          }
        } else {
          final a = CashAccount(
            id: _stableIdFromKey('cash', key),
            name: name.isEmpty ? 'Wallet' : name,
            balance: opening,
          );
          await cashRepository.createWallet(a);
          keyToId[key] = a.id;
        }
        if (opening != 0) {
          await transactionRepository.createOpeningBalance(
            accountId: keyToId[key]!,
            amount: opening,
            bookingDate: date,
            description: 'Opening balance',
          );
        }
      } else if (recordType == 'CARD') {
        final c = CreditCard(
          id: _stableIdFromKey('card', key),
          nickname: name.isEmpty ? 'Credit card' : name,
          holderName: 'You',
          bankName: bank.isEmpty ? 'Bank' : bank,
          creditLimit: 0,
          billingDay: 1,
          dueDay: 1,
          annualFee: 0,
          cashbackSummary: '',
          faces: last4.isEmpty
              ? const []
              : [
                  CardFace(
                    id: _stableIdFromKey('face', key),
                    scheme: 'Card',
                    last4: last4,
                  ),
                ],
        );
        await cardRepository.upsertCard(c);
        keyToId[key] = c.id;
        if (opening != 0) {
          await transactionRepository.createOpeningBalance(
            accountId: c.id,
            amount: opening,
            bookingDate: date,
            description: 'Opening balance (card due)',
          );
        }
      }
    }

    // Second pass: transactions.
    for (final row in rows.skip(1)) {
      if (row.trim().isEmpty) continue;
      final cols = splitRow(row);
      final recordType = cell(cols, 'recordType').toUpperCase();
      if (recordType != 'TXN') continue;

      final kind = cell(cols, 'kind').toLowerCase();
      final amount = double.tryParse(cell(cols, 'amount')) ?? 0.0;
      final date = DateTime.tryParse(cell(cols, 'date')) ?? DateTime.now();
      final category = cell(cols, 'category');
      final description = cell(cols, 'description');
      final tagsStr = cell(cols, 'tags');
      final tags = tagsStr.isEmpty
          ? const <String>[]
          : tagsStr
              .split(RegExp(r'[;|,]'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(growable: false);

      if (kind == 'income' || kind == 'expense' || kind == 'opening') {
        final accountKey = cell(cols, 'accountKey');
        final accountId = keyToId[accountKey];
        if (accountId == null) continue;

        if (kind == 'income') {
          await transactionRepository.createIncome(
            accountId: accountId,
            amount: amount,
            categoryId: category,
            bookingDate: date,
            description: description,
            tags: tags,
          );
        } else if (kind == 'expense') {
          await transactionRepository.createExpense(
            accountId: accountId,
            amount: amount,
            categoryId: category,
            bookingDate: date,
            description: description,
            tags: tags,
          );
        } else {
          await transactionRepository.createOpeningBalance(
            accountId: accountId,
            amount: amount,
            bookingDate: date,
            description: description.isEmpty ? 'Opening balance' : description,
          );
        }
      } else if (kind == 'transfer') {
        final fromKey = cell(cols, 'fromKey');
        final toKey = cell(cols, 'toKey');
        final fromId = keyToId[fromKey];
        final toId = keyToId[toKey];
        if (fromId == null || toId == null) continue;
        await transactionRepository.createTransfer(
          fromAccountId: fromId,
          toAccountId: toId,
          amount: amount,
          bookingDate: date,
          description: description,
          notes: _notesFromTags(tags),
        );
      }
    }
  }
}

List<dynamic> _asList(dynamic v) {
  if (v is List) return v;
  return const <dynamic>[];
}

String _stableIdFromKey(String prefix, String key) {
  final safe = key.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  return '${prefix}_$safe';
}

Map<String, dynamic> _savingsToJson(SavingsAccount a) => {
      'id': a.id,
      'bankName': a.bankName,
      'accountNickname': a.accountNickname,
      'accountType': a.accountType,
      'maskedAccountNumber': a.maskedAccountNumber,
      'ifsc': a.ifsc,
      'branchName': a.branchName,
      'currentBalance': a.currentBalance,
      'availableBalance': a.availableBalance,
      'interestRate': a.interestRate,
      'minBalanceRequired': a.minBalanceRequired,
      'isSalaryAccount': a.isSalaryAccount,
      'hasNominee': a.hasNominee,
      'lastInterestCreditedOn': a.lastInterestCreditedOn.toIso8601String(),
      'lastInterestAmount': a.lastInterestAmount,
      'isClosed': a.isClosed,
      'closedAt': a.closedAt?.toIso8601String(),
    };

SavingsAccount _savingsFromJson(dynamic v) {
  final m = (v as Map).cast<String, dynamic>();
  final now = DateTime.now();
  // Back-compat: older payloads used accountName.
  final nickname = (m['accountNickname'] ?? m['accountName'] ?? '').toString();
  return SavingsAccount(
    id: (m['id'] ?? '').toString(),
    bankName: (m['bankName'] ?? '').toString(),
    accountNickname: nickname.isEmpty ? 'Savings' : nickname,
    accountType: (m['accountType'] ?? 'Savings').toString(),
    maskedAccountNumber:
        (m['maskedAccountNumber'] ?? 'XXXX').toString().trim().isEmpty
            ? 'XXXX'
            : (m['maskedAccountNumber'] ?? 'XXXX').toString(),
    ifsc: (m['ifsc'] ?? '').toString(),
    branchName: (m['branchName'] ?? '').toString(),
    currentBalance: (m['currentBalance'] is num)
        ? (m['currentBalance'] as num).toDouble()
        : 0.0,
    availableBalance: (m['availableBalance'] is num)
        ? (m['availableBalance'] as num).toDouble()
        : 0.0,
    interestRate: (m['interestRate'] is num)
        ? (m['interestRate'] as num).toDouble()
        : 0.0,
    minBalanceRequired: (m['minBalanceRequired'] is num)
        ? (m['minBalanceRequired'] as num).toDouble()
        : 0.0,
    isSalaryAccount: (m['isSalaryAccount'] is bool)
        ? (m['isSalaryAccount'] as bool)
        : false,
    hasNominee:
        (m['hasNominee'] is bool) ? (m['hasNominee'] as bool) : false,
    lastInterestCreditedOn:
        DateTime.tryParse((m['lastInterestCreditedOn'] ?? '').toString()) ??
            now,
    lastInterestAmount: (m['lastInterestAmount'] is num)
        ? (m['lastInterestAmount'] as num).toDouble()
        : 0.0,
    isClosed: (m['isClosed'] is bool) ? (m['isClosed'] as bool) : false,
    closedAt: m['closedAt'] == null
        ? null
        : DateTime.tryParse(m['closedAt'].toString()),
  );
}

Map<String, dynamic> _cashToJson(CashAccount a) => {
      'id': a.id,
      'name': a.name,
      'balance': a.balance,
      'isClosed': a.isClosed,
      'closedAt': a.closedAt?.toIso8601String(),
    };

CashAccount _cashFromJson(dynamic v) {
  final m = (v as Map).cast<String, dynamic>();
  return CashAccount(
    id: (m['id'] ?? '').toString(),
    name: (m['name'] ?? m['accountName'] ?? '').toString(),
    balance: (m['balance'] is num) ? (m['balance'] as num).toDouble() : 0.0,
    isClosed: (m['isClosed'] is bool) ? (m['isClosed'] as bool) : false,
    closedAt: m['closedAt'] == null
        ? null
        : DateTime.tryParse(m['closedAt'].toString()),
  );
}

Map<String, dynamic> _cardToJson(CreditCard c) => {
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
      'closedAt': c.closedAt?.toIso8601String(),
      'faces': c.faces
          .map(
            (f) => {
              'id': f.id,
              'scheme': f.scheme,
              'last4': f.last4,
            },
          )
          .toList(growable: false),
    };

CreditCard _cardFromJson(dynamic v) {
  final m = (v as Map).cast<String, dynamic>();
  final facesRaw = m['faces'];
  final faces = <CardFace>[];
  if (facesRaw is List) {
    for (final f in facesRaw) {
      if (f is Map) {
        final fm = f.cast<String, dynamic>();
        final last4 = (fm['last4'] ?? '').toString();
        if (last4.isEmpty) continue;
        faces.add(
          CardFace(
            id: (fm['id'] ?? _stableIdFromKey('face', (m['id'] ?? '').toString()))
                .toString(),
            scheme: (fm['scheme'] ?? 'Card').toString(),
            last4: last4,
          ),
        );
      }
    }
  }
  // Back-compat for older payloads.
  final last4Legacy = (m['last4'] ?? '').toString();
  if (faces.isEmpty && last4Legacy.isNotEmpty) {
    faces.add(
      CardFace(
        id: _stableIdFromKey('face', (m['id'] ?? '').toString()),
        scheme: 'Card',
        last4: last4Legacy,
      ),
    );
  }
  return CreditCard(
    id: (m['id'] ?? '').toString(),
    nickname: (m['nickname'] ?? m['cardName'] ?? '').toString().isEmpty
        ? 'Credit card'
        : (m['nickname'] ?? m['cardName']).toString(),
    holderName: (m['holderName'] ?? 'You').toString(),
    bankName: (m['bankName'] ?? '').toString(),
    creditLimit:
        (m['creditLimit'] is num) ? (m['creditLimit'] as num).toDouble() : 0.0,
    billingDay: (m['billingDay'] is num) ? (m['billingDay'] as num).toInt() : 1,
    dueDay: (m['dueDay'] is num) ? (m['dueDay'] as num).toInt() : 1,
    annualFee:
        (m['annualFee'] is num) ? (m['annualFee'] as num).toDouble() : 0.0,
    cashbackSummary: (m['cashbackSummary'] ?? '').toString(),
    isClosed: (m['isClosed'] is bool) ? (m['isClosed'] as bool) : false,
    closedAt: m['closedAt'] == null
        ? null
        : DateTime.tryParse(m['closedAt'].toString()),
    faces: faces,
  );
}

Map<String, dynamic> _txnToJson(Transaction t) => {
      'id': t.id,
      'accountId': t.accountId,
      'type': t.type.name,
      'amount': t.amount,
      'bookingDate': t.bookingDate.toIso8601String(),
      'createdAt': t.createdAt.toIso8601String(),
      'updatedAt': t.updatedAt.toIso8601String(),
      'adjustmentDirection': t.adjustmentDirection?.name,
      'transferGroupId': t.transferGroupId,
      'counterAccountId': t.counterAccountId,
      'categoryId': t.categoryId,
      'description': t.description,
      'notes': t.notes,
      'tags': t.tags,
    };

Transaction _txnFromJson(dynamic v) {
  final m = (v as Map).cast<String, dynamic>();
  final typeName = (m['type'] ?? 'expense').toString();
  final type = TransactionType.values.firstWhere(
    (e) => e.name == typeName,
    orElse: () => TransactionType.expense,
  );
  final bookingDate =
      DateTime.tryParse((m['bookingDate'] ?? '').toString()) ?? DateTime.now();
  final createdAt =
      DateTime.tryParse((m['createdAt'] ?? '').toString()) ?? bookingDate;
  final updatedAt =
      DateTime.tryParse((m['updatedAt'] ?? '').toString()) ?? createdAt;

  AdjustmentDirection? adjustmentDirection;
  final adjName = (m['adjustmentDirection'] ?? '').toString();
  if (adjName.isNotEmpty) {
    adjustmentDirection = AdjustmentDirection.values
        .cast<AdjustmentDirection?>()
        .firstWhere(
          (e) => e?.name == adjName,
          orElse: () => null,
        );
  }

  // Back-compat: older payloads used transferToAccountId.
  final legacyTransferTo = m['transferToAccountId']?.toString();
  final counterAccountId =
      (m['counterAccountId'] ?? legacyTransferTo)?.toString();

  return Transaction(
    id: (m['id'] ?? '').toString(),
    accountId: (m['accountId'] ?? '').toString(),
    type: type,
    amount: (m['amount'] is num) ? (m['amount'] as num).toDouble() : 0.0,
    bookingDate: bookingDate,
    createdAt: createdAt,
    updatedAt: updatedAt,
    adjustmentDirection: adjustmentDirection,
    transferGroupId: m['transferGroupId']?.toString(),
    counterAccountId: counterAccountId,
    categoryId: m['categoryId']?.toString(),
    description: m['description']?.toString(),
    notes: m['notes']?.toString(),
    tags: (m['tags'] is List)
        ? (m['tags'] as List).map((e) => e.toString()).toList(growable: false)
        : const <String>[],
  );
}

String? _notesFromTags(List<String> tags, {String? existing}) {
  if (tags.isEmpty) return existing;
  final tagLine = 'tags: ${tags.join(", ")}';
  if (existing == null || existing.trim().isEmpty) return tagLine;
  return '$existing\n$tagLine';
}

