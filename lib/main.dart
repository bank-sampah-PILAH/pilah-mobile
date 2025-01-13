import 'package:boilerplate/app.dart';
import 'package:boilerplate/services/di.dart';
import 'package:flutter/material.dart';

import 'core/constants/app_key.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies(environment: AppKey.devEnv);
  runApp(const App());
}
