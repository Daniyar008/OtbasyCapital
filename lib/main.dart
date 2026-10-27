import 'package:flutter/material.dart';

import 'app.dart';
import 'app/app_store.dart';
import 'core/services/finance_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore(storage: FinanceRepository.local());
  await store.load();
  runApp(OtbasyApp(store: store));
}
