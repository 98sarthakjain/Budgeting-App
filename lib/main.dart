import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/app_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppContainer.init();
  runApp(const BudgetingApp());
}
