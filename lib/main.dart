import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/startup_app.dart';
import 'app/app_store.dart';
import 'core/config/supabase_config.dart';
import 'core/services/cloud_storage_service.dart';
import 'core/services/supabase_finance_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  runApp(StartupApp(initialize: initializeApplication));
}

Future<AppStore> initializeApplication() async {
  await Hive.initFlutter();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
    postgrestOptions: const PostgrestClientOptions(
      requestTimeout: Duration(seconds: 10),
      retryCount: 0,
    ),
  );
  final cloud = CloudStorageService.local(
    SupabaseFinanceService(Supabase.instance.client),
  );
  final store = AppStore(storage: cloud, cloud: cloud);
  await store.restoreCloudAccount();
  return store;
}
