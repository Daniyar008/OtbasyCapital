import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:otbasy_capital/app/app_store.dart';
import 'package:otbasy_capital/core/services/cloud_storage_service.dart';
import 'package:otbasy_capital/core/services/finance_cloud.dart';
import 'package:otbasy_capital/core/services/finance_repository.dart';
import 'package:otbasy_capital/core/services/storage_service.dart';
import 'package:otbasy_capital/features/transactions/models/money_entry.dart';

class FakeCloud implements FinanceCloud {
  @override
  CloudAccount? account;
  bool offline = false, confirmationRequired = false;
  final states = <String, Map<String, dynamic>>{};
  final uploads = <Map<String, dynamic>>[];
  int downloads = 0;
  @override
  Future<void> signIn(String email, String password) async {
    if (password != 'Valid2026') throw StateError('Invalid credentials');
    account = CloudAccount(
      id: email,
      email: email,
      name: email.split('@').first,
    );
  }

  @override
  Future<bool> signUp(String email, String password, String name) async {
    if (confirmationRequired) return false;
    account = CloudAccount(id: email, email: email, name: name);
    return true;
  }

  @override
  Future<void> signOut() async => account = null;
  @override
  Future<Map<String, dynamic>?> download(String userId) async {
    downloads++;
    if (offline) throw const SocketException('offline');
    return states[userId] == null
        ? null
        : jsonDecode(jsonEncode(states[userId])) as Map<String, dynamic>;
  }

  @override
  Future<void> upload(String userId, Map<String, dynamic> state) async {
    if (offline) throw const SocketException('offline');
    uploads.add(jsonDecode(jsonEncode(state)) as Map<String, dynamic>);
    states[userId] = jsonDecode(jsonEncode(state)) as Map<String, dynamic>
      ..removeWhere((key, _) => key.startsWith('cloud'));
  }
}

MoneyEntry entry(String id, int amount) => MoneyEntry(
  id: id,
  title: 'Дәріхана',
  amount: amount,
  income: false,
  category: 'Басқа',
  date: DateTime(2026, 10, 27),
  owner: 'Данияр',
);

void main() {
  late Directory directory;
  late FakeCloud backend;
  late CloudStorageService cloud;
  late Map<String, StorageService> caches;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('otbasy_cloud_test_');
    Hive.init(directory.path);
    backend = FakeCloud();
    caches = {};
    cloud = CloudStorageService(
      backend: backend,
      storageForAccount: (id) => caches.putIfAbsent(
        id,
        () => FinanceRepository(
          openBox: () => Hive.openBox<dynamic>('user_${id.hashCode}'),
        ),
      ),
    );
  });
  tearDown(() async {
    cloud.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'confirmed account starts empty; bad password never opens an account',
    () async {
      final store = AppStore(storage: cloud, cloud: cloud);
      await expectLater(
        store.login('a@example.com', 'wrong'),
        throwsStateError,
      );
      expect(store.signedIn, isFalse);
      backend.confirmationRequired = true;
      expect(
        await store.register('a@example.com', 'Valid2026', 'Данияр'),
        isFalse,
      );
      expect(store.signedIn, isFalse);
      expect(caches, isEmpty);
      await store.login('a@example.com', 'Valid2026');
      expect(store.signedIn, isTrue);
      expect(store.visibleEntries, isEmpty);
      expect(store.goals, isEmpty);
      expect(backend.states['a@example.com']!['entries'], isEmpty);
      store.dispose();
    },
  );

  test('offline add/edit/delete survive Hive reopen, then retry with explicit tombstones', () async {
    var store = AppStore(storage: cloud, cloud: cloud);
    await store.login('a@example.com', 'Valid2026');
    await store.saveEntry(entry('remove', 2000));
    backend.offline = true;
    await store.saveEntry(entry('keep', 3000));
    await store.saveEntry(entry('keep', 4000));
    await store.toggleFavorite('keep');
    await store.deleteEntry('remove');
    expect(store.storageError, isNull);
    expect(store.cloudError, isNotNull);
    final dirty = jsonDecode((await caches['a@example.com']!.read())!) as Map;
    expect(dirty['cloudDirty'], isTrue);
    expect(dirty['cloudDeleted_entries'], ['remove']);
    expect(dirty['cloudPending_entries'], ['keep']);
    store.dispose();
    await Hive.close();
    caches.clear();
    Hive.init(directory.path);
    store = AppStore(storage: cloud, cloud: cloud);
    await store.restoreCloudAccount();
    expect(store.entry('keep')!.amount, 4000);
    expect(store.entry('keep')!.favorite, isTrue);
    expect(store.entry('remove'), isNull);
    backend.offline = false;
    await store.syncCloud();
    expect(store.cloudError, isNull);
    final sent = backend.uploads.last;
    expect(sent['cloudDeleted_entries'], ['remove']);
    expect(sent['cloudPending_entries'], ['keep']);
    final clean = jsonDecode((await caches['a@example.com']!.read())!) as Map;
    expect(clean['cloudDirty'], isFalse);
    expect(clean['cloudDeleted_entries'], isEmpty);
    expect(clean['cloudPending_entries'], isEmpty);
    expect(store.entry('keep')!.amount, 4000);
    store.dispose();
  });

  test(
    'accounts use separate caches and never upload the previous user records',
    () async {
      final store = AppStore(storage: cloud, cloud: cloud);
      await store.login('a@example.com', 'Valid2026');
      await store.saveEntry(entry('private-a', 5000));
      await store.logout();
      expect(store.signedIn, isFalse);
      expect(store.accessibleEntries, isEmpty);
      await store.login('b@example.com', 'Valid2026');
      expect(store.accessibleEntries, isEmpty);
      expect(backend.states['b@example.com']!['entries'], isEmpty);
      await store.saveEntry(entry('private-b', 8000));
      await store.logout();
      await store.login('a@example.com', 'Valid2026');
      expect(store.entry('private-a')!.amount, 5000);
      expect(store.entry('private-b'), isNull);
      expect(caches.keys.toSet(), {'a@example.com', 'b@example.com'});
      store.dispose();
    },
  );

  test('first login with no cache and unavailable cloud blocks writes instead of replacing data', () async {
    backend.offline = true;
    final store = AppStore(storage: cloud, cloud: cloud);
    await store.login('a@example.com', 'Valid2026');
    expect(store.storageError, isNotNull);
    expect(store.accessibleEntries, isEmpty);
    await store.saveEntry(entry('blocked', 1000));
    expect(await caches['a@example.com']!.read(), isNull);
    expect(backend.uploads, isEmpty);
    backend.offline = false;
    await store.syncCloud();
    expect(store.storageError, isNull);
    expect(store.entry('blocked'), isNull);
    store.dispose();
  });
}
