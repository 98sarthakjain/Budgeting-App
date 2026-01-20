import 'package:flutter/material.dart';

import '../design/spacing.dart';
import '../design/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool elevated;
  final Color? backgroundColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.elevated = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme =
        AppTheme.lightColorScheme; // or Theme.of(context).colorScheme

    return Card(
      color: backgroundColor ?? scheme.surface,
      elevation: elevated ? 1 : 0,
      child: Padding(
        padding:
            padding ??
            const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
        child: child,
      ),
    );
  }
}
