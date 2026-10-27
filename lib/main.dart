import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'app/app_store.dart';
import 'core/config/supabase_config.dart';
import 'core/services/cloud_storage_service.dart';
import 'core/services/supabase_finance_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  runApp(
    OtbasyApp(store: store, initialLocation: store.signedIn ? '/home' : '/'),
  );
}
