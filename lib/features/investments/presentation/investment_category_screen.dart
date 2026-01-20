import 'package:flutter/material.dart';

import 'package:budgeting_app/core/design/spacing.dart';
import 'package:budgeting_app/core/widgets/app_card.dart';
import 'package:budgeting_app/features/investments/domain/investment_account.dart';
import 'package:budgeting_app/features/investments/domain/investment_type.dart';
import 'package:budgeting_app/features/investments/data/investment_repository.dart';
import 'package:budgeting_app/features/investments/presentation/investment_detail_screen.dart';
import 'package:budgeting_app/core/services/app_currency_service.dart';

class InvestmentCategoryScreen extends StatefulWidget {
  final InvestmentType type;
  final InvestmentRepository repository;

  const InvestmentCategoryScreen({
    super.key,
    required this.type,
    required this.repository,
  });

  @override
  State<InvestmentCategoryScreen> createState() =>
      _InvestmentCategoryScreenState();
}

class _InvestmentCategoryScreenState extends State<InvestmentCategoryScreen> {
  late Future<List<InvestmentAccount>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getByType(widget.type);
  }

  @override
  Widget build(BuildContext context) {
    final title = _label(widget.type);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: textTheme.titleLarge),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FutureBuilder<List<InvestmentAccount>>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snap.data!;

              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return _InvestmentTile(item: item);
                },
              );
            },
          ),
        ),
      ),
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
        return 'Fixed Deposits';
    }
  }
}

class _InvestmentTile extends StatelessWidget {
  final InvestmentAccount item;

  const _InvestmentTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final currency = AppCurrencyService.instance;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => InvestmentDetailScreen(account: item),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.category,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invested: ${currency.format(item.investedAmount)}',
                    style: textTheme.bodyMedium,
                  ),
                  Text(
                    'Current: ${currency.format(item.currentValue)}',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
