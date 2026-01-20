import 'package:flutter/material.dart';

import 'package:budgeting_app/core/design/spacing.dart';
import 'package:budgeting_app/core/widgets/app_card.dart';
import 'package:budgeting_app/features/insurance/data/insurance_repository.dart';
import 'package:budgeting_app/features/insurance/domain/insurance_policy.dart';
import 'package:budgeting_app/features/insurance/presentation/insurance_detail_screen.dart';
import 'package:budgeting_app/core/services/app_currency_service.dart';

class InsuranceListScreen extends StatefulWidget {
  final InsuranceRepository repository;

  const InsuranceListScreen({super.key, required this.repository});

  @override
  State<InsuranceListScreen> createState() => _InsuranceListScreenState();
}

class _InsuranceListScreenState extends State<InsuranceListScreen> {
  late Future<List<InsurancePolicy>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getAll();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Insurance', style: textTheme.titleLarge),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FutureBuilder<List<InsurancePolicy>>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load policies',
                      style: textTheme.bodyMedium,
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              }

              final policies = snap.data!;

              return ListView.separated(
                itemCount: policies.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, i) {
                  final p = policies[i];
                  return AppCard(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => InsuranceDetailScreen(policy: p),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            _PolicyIcon(type: p.type),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.policyName,
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    p.insurerName,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Renews: ${_formatDate(p.expiryDate)}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              AppCurrencyService.instance.format(
                                p.premiumAmount,
                              ),
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PolicyIcon extends StatelessWidget {
  final InsuranceType type;

  const _PolicyIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    IconData icon;
    switch (type) {
      case InsuranceType.health:
        icon = Icons.health_and_safety;
        break;
      case InsuranceType.life:
        icon = Icons.favorite;
        break;
      case InsuranceType.term:
        icon = Icons.shield;
        break;
      case InsuranceType.motor:
        icon = Icons.directions_car;
        break;
      case InsuranceType.travel:
        icon = Icons.flight_takeoff;
        break;
      default:
        icon = Icons.home_filled;
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: scheme.surfaceVariant,
      child: Icon(icon, color: scheme.primary),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
