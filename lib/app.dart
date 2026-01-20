import 'package:flutter/material.dart';

import 'core/routes.dart';
import 'core/design/app_theme.dart';

class BudgetingApp extends StatelessWidget {
  const BudgetingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budgeting App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.home,
      routes: appRoutes, // 👈 single source of truth
    );
  }
}
