import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:otbasy_capital/app/app_store.dart';
import 'package:otbasy_capital/core/services/cloud_storage_service.dart';
import 'package:otbasy_capital/core/services/finance_cloud.dart';
import 'package:otbasy_capital/core/services/realtime_state.dart';
import 'package:otbasy_capital/core/services/storage_service.dart';

class RealtimeFakeCloud implements FinanceCloud, RealtimeFinanceCloud {
  @override
  CloudAccount? account;
  final updates = StreamController<List<Map<String, dynamic>>>.broadcast();

  @override
  Future<void> signIn(String email, String password) async {
    account = const CloudAccount(
      id: 'user-a',
      email: 'user@example.com',
      name: 'Данияр',
    );
  }

  @override
  Future<bool> signUp(String email, String password, String name) async => true;

  @override
  Future<void> signOut() async => account = null;

  @override
  Future<Map<String, dynamic>?> download(String userId) async => null;

  @override
  Future<void> upload(String userId, Map<String, dynamic> state) async {}

  @override
  Stream<List<Map<String, dynamic>>> watchEntries(String userId) =>
      updates.stream;
}

void main() {
  test(
    'Realtime event replaces the operation list and updates the UI state',
    () async {
      final backend = RealtimeFakeCloud();
      final cloud = CloudStorageService(
        backend: backend,
        storageForAccount: (_) => MemoryStorageService(),
      );
      final store = AppStore(storage: cloud, cloud: cloud);
      await store.login('user@example.com', 'Valid2026');
      backend.updates.add([
        {
          'id': 'remote-1',
          'family_id': 'family-main',
          'title': 'Онлайн өзгеріс',
          'amount': 2500,
          'income': false,
          'category': 'Басқа',
          'entry_date': '2026-11-03T10:00:00.000Z',
          'owner_name': 'Данияр',
          'note': 'Realtime сынағы',
          'shared': true,
          'favorite': false,
          'receipt_path': null,
        },
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(store.realtimeState, RealtimeState.connected);
      expect(store.entry('remote-1')?.title, 'Онлайн өзгеріс');
      await backend.updates.close();
      store.dispose();
      cloud.dispose();
    },
  );
}
