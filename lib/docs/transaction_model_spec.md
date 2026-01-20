# 🧩 Transaction Model & Repository Specification
_Last updated: 2025-11-17_

This document defines the **Transaction entity** and the **TransactionRepository API**.  
All account modules (Savings, Cash, Wallets, CCs, Loans, Investments) rely on this spec.

---

# 1. Transaction Types

```dart
enum TransactionType {
  income,
  expense,
  transferIn,
  transferOut,
  openingBalance,
  adjustment,
}

Why:

Supports all financial flows

Keeps analytics clean

Aligns with global financial rules

2. Transaction Entity Specification
class Transaction {
  final String id;

  final String accountId;

  final DateTime bookingDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  final double amount; // always positive
  final TransactionType type;

  final AdjustmentDirection? adjustmentDirection;

  final String? transferGroupId;
  final String? counterAccountId;

  final String? categoryId;
  final String? description;
  final String? notes;

  final List<String> tags;

  final bool isCleared;
}



AdjustmentDirection

enum AdjustmentDirection {
  increase, // actual > ledger
  decrease, // actual < ledger
}


3. Balance Computation Logic

Balance = sum of transactions:

ADD:

income

transferIn

openingBalance

adjustment (increase)

SUBTRACT:

expense

transferOut

adjustment (decrease)

Not included in income/expense reports:

transferIn/transferOut

openingBalance

adjustment


4. TransactionRepository Interface
Core creation methods
abstract class TransactionRepository {
  Future<Transaction> createIncome(...);
  Future<Transaction> createExpense(...);

  Future<Transaction> createOpeningBalance(...);

  Future<Transaction> createAdjustment(...);

  Future<List<Transaction>> createTransfer(...);

  Future<Transaction> updateTransaction(Transaction txn);
  Future<void> deleteTransaction(String id);



Query methods

Future<Transaction?> getById(String id);

Future<List<Transaction>> getByAccount({
  required String accountId,
  DateTime? from,
  DateTime? to,
});

Stream<List<Transaction>> watchByAccount({
  required String accountId,
  DateTime? from,
  DateTime? to,
});

Future<List<Transaction>> query({
  List<String>? accountIds,
  List<TransactionType>? types,
  String? categoryId,
  DateTime? from,
  DateTime? to,
  bool? onlyCleared,
  String? textSearch,
});


Balance helpers

Future<double> computeBalance({
  required String accountId,
  DateTime? until,
});

Future<IncomeExpenseSummary> computeIncomeExpenseSummary({
  List<String>? accountIds,
  DateTime? from,
  DateTime? to,
});

5. Opening Balances & Reconciliation

New accounts → openingBalance transaction

Editing balance → adjustment transaction

Account closing depends on transaction count

6. Transfer Rules

createTransfer() must generate:

transferOut on source account

transferIn on destination account

Both share:

transferGroupId

This keeps many modules consistent:

Credit card bill payments

Wallet → Bank transfers

Savings → Investments

Cash withdrawals/deposits

7. Implementation Plan (Later)

InMemoryTransactionRepository

Integrate Savings & Cash modules using computeBalance()

Integrate Credit Cards

Integrate Loans

Integrate Investments

Replace in-memory with Hive implementation


END OF SPEC


---

## 🎯 You now have two official architecture documents.

These are stable, reusable, and will ensure:

- We never break the financial logic
- We never break balances
- All modules behave consistently
- Multi-device support works cleanly
- Hive integration becomes easy

---

If you want, I can now generate:

### **“apply changes: transaction.dart + transaction_repository.dart (abstract interface)”**

Just say the word.
