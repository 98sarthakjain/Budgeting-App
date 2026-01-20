// lib/features/cards/presentation/credit_cards_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:budgeting_app/core/design/spacing.dart';
import 'package:budgeting_app/core/design/app_theme.dart';
import 'package:budgeting_app/core/services/app_currency_service.dart';
import 'package:budgeting_app/features/cards/data/card_repository.dart';
import 'package:budgeting_app/features/cards/domain/credit_card.dart';
import 'package:budgeting_app/features/cards/presentation/add_card_screen.dart';
import 'package:budgeting_app/features/cards/presentation/credit_card_detail_screen.dart';
import 'package:budgeting_app/features/transactions/data/transaction_repository.dart';
import 'package:budgeting_app/features/transactions/domain/transaction.dart';

class CreditCardsScreen extends StatefulWidget {
  final CardRepository repository;
  final TransactionRepository transactionRepository;

  const CreditCardsScreen({
    super.key,
    required this.repository,
    required this.transactionRepository,
  });

  @override
  State<CreditCardsScreen> createState() => _CreditCardsScreenState();
}

class _CreditCardsScreenState extends State<CreditCardsScreen> {
  late final StreamSubscription<List<dynamic>> _txnSub;
  bool _showClosed = false;

  @override
  Widget build(BuildContext context) {
    final currency = AppCurrencyService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Credit Cards')),
      body: SafeArea(
        child: Column(
          children: [
            // Header (total due + toggle)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: StreamBuilder<List<CreditCard>>(
                stream: widget.repository.watchAllCards(
                  includeClosed: _showClosed,
                ),
                builder: (context, snapshot) {
                  final cards = snapshot.data ?? const <CreditCard>[];
                  return _Header(
                    cards: cards,
                    transactionRepository: widget.transactionRepository,
                    currency: currency,
                    showClosed: _showClosed,
                    onToggleClosed: (value) {
                      setState(() {
                        _showClosed = value;
                      });
                    },
                  );
                },
              ),
            ),

            // Cards list
            Expanded(
              child: StreamBuilder<List<CreditCard>>(
                stream: widget.repository.watchAllCards(
                  includeClosed: _showClosed,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Failed to load cards',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  }

                  final cards = snapshot.data!;
                  if (cards.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'No credit cards added yet.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.xl,
                      top: AppSpacing.sm,
                    ),
                    itemCount: cards.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.lg),
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return _CenteredCard(
                        child: _CreditCardTile(
                          card: card,
                          transactionRepository: widget.transactionRepository,
                          onTapDetails: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CreditCardDetailScreen(
                                  card: card,
                                  transactionRepository:
                                      widget.transactionRepository,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => AddCardScreen(
                      repository: widget.repository,
                      transactionRepository: widget.transactionRepository,
                    ),
                  ),
                );
                if (changed == true) {
                  // StreamBuilder will auto-refresh
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Credit Card'),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final List<CreditCard> cards;
  final TransactionRepository transactionRepository;
  final AppCurrencyService currency;
  final bool showClosed;
  final ValueChanged<bool> onToggleClosed;

  const _Header({
    required this.cards,
    required this.transactionRepository,
    required this.currency,
    required this.showClosed,
    required this.onToggleClosed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<List<double>>(
          future: Future.wait(
            cards.map(
              (c) => transactionRepository.computeBalance(accountId: c.id),
            ),
          ),
          builder: (context, snapshot) {
            double totalDue = 0;
            if (snapshot.hasData) {
              totalDue = snapshot.data!.fold<double>(0, (sum, v) => sum + v);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STATEMENT DUE',
                  style: textTheme.bodyMedium?.copyWith(
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withAlpha(((0.6) * 255).round()),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      currency.format(totalDue),
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.expand_more, size: 22),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Statement due for ${cards.length} card${cards.length == 1 ? '' : 's'}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withAlpha(((0.6) * 255).round()),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Switch(value: showClosed, onChanged: onToggleClosed),
            const SizedBox(width: AppSpacing.xs),
            const Text('Show closed cards'),
          ],
        ),
      ],
    );
  }
}

class _CenteredCard extends StatelessWidget {
  final Widget child;

  const _CenteredCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width * 0.9; // slightly inset from edges

    return Center(
      child: SizedBox(
        width: cardWidth,
        child: AspectRatio(aspectRatio: 16 / 9, child: child),
      ),
    );
  }
}

class _CreditCardTile extends StatelessWidget {
  final CreditCard card;
  final TransactionRepository transactionRepository;
  final VoidCallback onTapDetails;

  const _CreditCardTile({
    required this.card,
    required this.transactionRepository,
    required this.onTapDetails,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final gradients = AppTheme.cardGradients;
    final colors = gradients[card.hashCode.abs() % gradients.length];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Card body
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: bank + amount + pay button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bank + nickname + CLOSED badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.bankName,
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withAlpha(((0.9) * 255).round()),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  card.nickname,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (card.isClosed) ...[
                                const SizedBox(width: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(((0.25) * 255).round()),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'CLOSED',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // Amount due + due date + Pay now
                    FutureBuilder<double>(
                      future: transactionRepository.computeBalance(
                        accountId: card.id,
                      ),
                      builder: (context, snapshot) {
                        final amountDue = snapshot.data ?? 0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppCurrencyService.instance.format(amountDue),
                              style: textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'DUE DAY ${card.dueDay.toString().padLeft(2, '0')}',
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white.withAlpha(((0.8) * 255).round()),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: card.isClosed
                                    ? Colors.white.withAlpha(((0.35) * 255).round())
                                    : Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: card.isClosed
                                  ? null
                                  : () {
                                      // Later this will create a payment transaction.
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Payment flow coming soon (linked to transactions).',
                                          ),
                                        ),
                                      );
                                    },
                              child: const Text('Pay now'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.credit_card,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      card.primaryFace?.last4.isNotEmpty == true
                          ? '•• ${card.primaryFace!.last4}'
                          : '••••',
                      style: textTheme.bodyLarge?.copyWith(color: Colors.white),
                    ),
                    const Spacer(),
                    Text(
                      card.holderName.toUpperCase(),
                      style: textTheme.bodyMedium?.copyWith(
                        letterSpacing: 1.5,
                        color: Colors.white.withAlpha(((0.9) * 255).round()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bottom "View details" pill
          Positioned(
            bottom: AppSpacing.sm,
            left: 0,
            right: 0,
            child: Center(
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black.withAlpha(((0.15) * 255).round()),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: onTapDetails,
                child: const Text('View details'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
