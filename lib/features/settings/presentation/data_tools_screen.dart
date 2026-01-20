import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:budgeting_app/core/design/spacing.dart';
import 'package:budgeting_app/core/widgets/app_card.dart';

import 'package:budgeting_app/core/services/ledger_portability_service.dart';
import 'package:budgeting_app/features/cards/data/card_repository.dart';
import 'package:budgeting_app/features/cash/data/cash_account_repository.dart';
import 'package:budgeting_app/features/savings/data/savings_account_repository.dart';
import 'package:budgeting_app/features/transactions/data/transaction_repository.dart';

class DataToolsScreen extends StatefulWidget {
  final TransactionRepository transactionRepository;
  final SavingsAccountRepository savingsRepository;
  final CashAccountRepository cashRepository;
  final CardRepository cardRepository;

  const DataToolsScreen({
    super.key,
    required this.transactionRepository,
    required this.savingsRepository,
    required this.cashRepository,
    required this.cardRepository,
  });

  @override
  State<DataToolsScreen> createState() => _DataToolsScreenState();
}

class _DataToolsScreenState extends State<DataToolsScreen> {
  late final LedgerPortabilityService _io;

  @override
  void initState() {
    super.initState();
    _io = LedgerPortabilityService(
      transactionRepository: widget.transactionRepository,
      savingsRepository: widget.savingsRepository,
      cashRepository: widget.cashRepository,
      cardRepository: widget.cardRepository,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data tools'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Backup / restore',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.ios_share,
                    title: 'Export backup (JSON) → copy to clipboard',
                    subtitle:
                        'Creates a portable snapshot. Paste into Notes/Drive for safety.',
                    onTap: () => _exportJson(context),
                  ),
                  const Divider(height: 1),
                  _ActionTile(
                    icon: Icons.download,
                    title: 'Import backup (JSON) (paste)',
                    subtitle:
                        'Replaces current data (recommended during testing).',
                    onTap: () => _importJson(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(
              'Spreadsheet import (CSV)',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.table_view,
                    title: 'Copy CSV template',
                    subtitle:
                        'Use this in Google Sheets/Excel. Then copy the CSV text back here.',
                    onTap: () => _copyCsvTemplate(context),
                  ),
                  const Divider(height: 1),
                  _ActionTile(
                    icon: Icons.upload_file,
                    title: 'Import CSV (paste)',
                    subtitle:
                        'Creates accounts, cards and transactions in one shot.',
                    onTap: () => _importCsv(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(
              'Testing utilities',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.restart_alt,
                    title: 'Reset all local data',
                    subtitle:
                        'Deletes accounts, cards and transactions from this device.',
                    danger: true,
                    onTap: () => _confirmReset(context),
                  ),
                  const Divider(height: 1),
                  _ActionTile(
                    icon: Icons.auto_fix_high,
                    title: 'Seed sample data',
                    subtitle:
                        'Adds a small sample dataset for quick UI testing.',
                    onTap: () => _confirmSeed(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Tip: During your 2–3 day manual testing, export a backup before any risky changes (like big imports) so you can restore instantly.',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportJson(BuildContext context) async {
    final json = await _io.exportBackupJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Backup copied'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Backup JSON has been copied to your clipboard. Paste it into Notes/Drive.',
                ),
                const SizedBox(height: AppSpacing.md),
                SelectableText(
                  json,
                  maxLines: 10,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importJson(BuildContext context) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Import backup (JSON)'),
          content: SizedBox(
            width: 560,
            child: TextField(
              controller: controller,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'Paste backup JSON here…',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Import (replace)'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;

    final text = controller.text.trim();
    if (text.isEmpty) return;

    try {
      await _io.importBackupJson(text, replace: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imported backup.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import failed. Check JSON format.')),
      );
    }
  }

  Future<void> _copyCsvTemplate(BuildContext context) async {
    final template = LedgerPortabilityService.csvTemplate();
    await Clipboard.setData(ClipboardData(text: template));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV template copied to clipboard.')),
    );
  }

  Future<void> _importCsv(BuildContext context) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Import CSV (paste)'),
          content: SizedBox(
            width: 560,
            child: TextField(
              controller: controller,
              maxLines: 12,
              decoration: const InputDecoration(
                hintText: 'Paste CSV text here…',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Import (replace)'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;

    final text = controller.text;
    if (text.trim().isEmpty) return;
    try {
      await _io.importCsv(text, replace: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imported CSV.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV import failed.')),
      );
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset all data?'),
          content: const Text(
            'This will delete all accounts, cards and transactions on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    await _io.resetAllData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data cleared.')),
    );
  }

  Future<void> _confirmSeed(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seed sample data?'),
          content: const Text(
            'Adds a small sample dataset (accounts + a few transactions).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Seed'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    await _io.seedSampleData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seeded sample data.')),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.surfaceVariant,
        child: Icon(
          icon,
          color: danger ? scheme.error : scheme.primary,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
