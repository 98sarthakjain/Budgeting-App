# 📘 Global Financial Rules — Budgeting App Core Specification
_Last updated: 2025-11-17_

These rules define the **financial correctness model** of the Budgeting App.  
All modules (Savings, Cash, Wallets, Credit Cards, Loans, Investments, Insurance)  
**must** follow these rules to ensure consistency, reliability, and predictable behavior.

---

# 1. Ledger Is the Source of Truth

### Rule 1.1  
All account balances are **computed from transactions**.

Balances are not stored as mutable fields.

### Formula
balance = sum(
openingBalance

income

expense

transferIn

transferOut

adjustment

)

### Result:
- Consistent across devices (mobile/web/desktop)
- No silent corruption
- Correct reconciliation and auditability

---

# 2. Adjustment Transactions (Not Income/Expense)

### Rule 2.1  
**Adjustments MUST NOT count as income or expense.**

Adjustments exist only to reconcile the app’s ledger with real-world account balances.

### Adjustment properties:
- Affects balance
- Does NOT appear in:
  - Monthly income
  - Monthly expenses
  - Category charts
  - Savings rate
  - Budgets
  - Credit card payoff analytics

### UI rule:
Show adjustments as special system entries, visually distinct.

---

# 3. Editing an Account Balance = Adjustment Transaction

### Rule 3.1  
Editing a balance must **never directly mutate account.currentBalance**.

Instead:

- Compute delta:

delta = newBalance - ledgerBalance


- If `delta != 0`, create an **Adjustment Transaction**.

### Example

App says balance = ₹102,000  
Bank app says = ₹101,500  
Delta = –500 → create:

Transaction {
type: adjustment,
adjustmentDirection: decrease,
amount: 500,
}


Now ledger matches reality without corrupting reports.

---

# 4. Account Deletion vs Closing

### Rule 4.1 — Hard Delete  
Allowed **only** when the account has **zero transactions**.

### Rule 4.2 — Close Account (Soft Delete)
If the account has **1+ transactions**, deletion becomes closure.

Closed accounts:
- Hidden from everyday lists
- Remain in all reports & history
- Cannot receive new transactions
- Can be re-opened

### UX copy:
> “This account has transaction history and cannot be deleted.  
> You may close it instead.”

---

# 5. Opening Balances Are Transactions

A user-entered starting balance for a new account is recorded as:

TransactionType.openingBalance


This ensures:
- Clean history
- Correct balance reconstruction
- Ability to sync across devices

---

# 6. Transfers Between Accounts

Transfers must create **two transactions**:

fromAccount → transferOut
toAccount → transferIn


Both share a `transferGroupId`.

Transfers:
- Affect balances
- Do NOT affect income/expense analytics

---

# 7. Account Status Model

Every account has:

enum AccountStatus { active, closed }

Rules:
- Closed accounts cannot accept transactions.
- Closed accounts remain visible in historical views.

---

# 8. Universal Consistency Rules

These apply across all modules (Savings, Wallets, Loans, CCs, Investments):

### Rule 8.1  
No module may modify balances directly.

### Rule 8.2  
Every module must:
- Create opening balance transactions
- Use adjustment transactions for reconciliation
- Respect account closing rules
- Use transfers for inter-account flows

---

# 9. Real-World Alignment

If ledger ≠ real world:
- Adjustment transaction is created
- Reports remain correct

If bank sync is implemented later:
- Incoming data becomes transactions
- Never direct balance overwrites

---

# 10. Cross-Device Consistency (Mobile + Web)

Because balance = sum(transactions):
- Sync is trivial
- Conflicts are minimized
- Computations are deterministic

---

# ✔ Summary Table

| Operation | What Happens | In Reports? | Affects Balance? |
|----------|--------------|-------------|------------------|
| Income | income txn | YES | YES |
| Expense | expense txn | YES | YES |
| Transfer | 2 txns | NO | YES |
| Adjustment | adjustment txn | NO | YES |
| Opening Balance | openingBalance txn | NO | YES |
| Delete acct (no txns) | Hard delete | N/A | N/A |
| Delete acct (has txns) | Soft-close | N/A | N/A |

---

# END OF SPEC
