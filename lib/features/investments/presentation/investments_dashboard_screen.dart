import 'package:flutter/material.dart';

import 'package:budgeting_app/core/design/spacing.dart';
import 'package:budgeting_app/core/widgets/app_card.dart';
import 'package:budgeting_app/features/investments/domain/investment_account.dart';
import 'package:budgeting_app/features/investments/domain/investment_type.dart';
import 'package:budgeting_app/features/investments/data/investment_repository.dart';
import 'package:budgeting_app/features/investments/presentation/investment_category_screen.dart';
import 'package:budgeting_app/core/services/app_currency_service.dart';

class InvestmentsDashboardScreen extends StatefulWidget {
  final InvestmentRepository repository;

  const InvestmentsDashboardScreen({super.key, required this.repository});

  @override
  State<InvestmentsDashboardScreen> createState() =>
      _InvestmentsDashboardScreenState();
}

class _InvestmentsDashboardScreenState
    extends State<InvestmentsDashboardScreen> {
  late Future<List<InvestmentAccount>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getAll();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currency = AppCurrencyService.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text('Investments', style: textTheme.titleLarge),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FutureBuilder<List<InvestmentAccount>>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData)
                return const Center(child: CircularProgressIndicator());
              final items = snap.data!;

              final totalInvested = items.fold<double>(
                0,
                (s, i) => s + i.investedAmount,
              );
              final totalCurrent = items.fold<double>(
                0,
                (s, i) => s + i.currentValue,
              );
              final totalPL = totalCurrent - totalInvested;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PortfolioHeader(
                    invested: totalInvested,
                    current: totalCurrent,
                    profitLoss: totalPL,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Text('Categories', style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),

                  _CategoryGrid(
                    onTapCategory: (type) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => InvestmentCategoryScreen(
                            type: type,
                            repository: widget.repository,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PortfolioHeader extends StatelessWidget {
  final double invested;
  final double current;
  final double profitLoss;

  const _PortfolioHeader({
    required this.invested,
    required this.current,
    required this.profitLoss,
  });

  @override
  Widget build(BuildContext context) {
    final currency = AppCurrencyService.instance;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isGain = profitLoss >= 0;

    return AppCard(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Value',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimary.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currency.format(current),
              style: textTheme.headlineMedium?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Invested: ${currency.format(invested)}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimary,
                  ),
                ),
                Text(
                  (isGain ? '+ ' : '− ') + currency.format(profitLoss.abs()),
                  style: textTheme.bodyMedium?.copyWith(
                    color: isGain ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final void Function(InvestmentType type) onTapCategory;

  const _CategoryGrid({required this.onTapCategory});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final cats = {
      InvestmentType.mutualFund: Icons.trending_up,
      InvestmentType.stock: Icons.show_chart,
      InvestmentType.nps: Icons.savings,
      InvestmentType.gold: Icons.circle,
      InvestmentType.fd: Icons.account_balance,
    };

    return GridView.builder(
      shrinkWrap: true,
      itemCount: cats.length,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.lg,
        mainAxisSpacing: AppSpacing.lg,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (_, i) {
        final type = cats.keys.elementAt(i);
        final icon = cats[type]!;

        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onTapCategory(type),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surfaceVariant,
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Icon(icon, color: scheme.primary, size: 26),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(_label(type), style: textTheme.bodyMedium),
            ],
          ),
        );
      },
    );
  }

  String _label(InvestmentType type) {
    switch (type) {
      case InvestmentType.mutualFund:
        return 'Mutual Funds';
      case InvestmentType.stock:
        return 'Stocks';
      case InvestmentType.nps:
        return 'NPS';
      case InvestmentType.gold:
        return 'Gold';
      case InvestmentType.fd:
        return 'FDs';
    }
  }
}
