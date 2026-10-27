import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:otbasy_capital/app/app_store.dart';
import 'package:otbasy_capital/core/services/finance_repository.dart';
import 'package:otbasy_capital/core/services/storage_service.dart';
import 'package:otbasy_capital/features/transactions/models/money_entry.dart';
import 'package:otbasy_capital/features/transactions/models/entry_query.dart';

class Offline extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      throw StateError('Network must not be used for local operations');
}

void main() {
  late Directory directory;
  late FinanceRepository repository;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('otbasy_hive_test_');
    Hive.init(directory.path);
    repository = FinanceRepository(
      openBox: () => Hive.openBox<dynamic>('finance'),
    );
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('offline CRUD, favorites and five model relations survive database reopening', () async {
    await HttpOverrides.runZoned(() async {
      var store = AppStore(storage: repository);
      await store.load();
      await store.saveEntry(
        MoneyEntry(
          id: 'new',
          title: 'Дәріхана',
          amount: 2000,
          income: false,
          category: 'Басқа',
          date: DateTime(2026, 10, 26),
          owner: 'Данияр',
        ),
      );
      expect(store.balance, 223000);
      await store.saveEntry(
        MoneyEntry(
          id: 'new',
          title: 'Дәріхана',
          amount: 1000,
          income: false,
          category: 'Басқа',
          date: DateTime(2026, 10, 26),
          owner: 'Данияр',
        ),
      );
      await store.toggleFavorite('new');
      await store.deleteEntry('transport');
      final expected = store.balance;
      final state = Hive.box<dynamic>('finance').get('state') as Map;
      expect(state['families'], hasLength(1));
      final members = (state['members'] as List)
          .map((m) => (m as Map)['id'])
          .toSet();
      for (final entry in state['entries'] as List) {
        expect(members, contains(entry['ownerId']));
        expect(entry['familyId'], 'family-main');
      }
      expect(state['goals'], isNotEmpty);
      expect(state['reminders'], isNotEmpty);
      store.dispose();
      await repository.close();
      await Hive.close();
      Hive.init(directory.path);
      repository = FinanceRepository(
        openBox: () => Hive.openBox<dynamic>('finance'),
      );
      store = AppStore(storage: repository);
      await store.load();
      expect(store.storageError, isNull);
      expect(store.entry('new')!.amount, 1000);
      expect(store.entry('new')!.favorite, isTrue);
      expect(store.entry('transport'), isNull);
      expect(store.balance, expected);
      expect(
        directory.listSync().whereType<File>().any(
          (f) => f.path.endsWith('.hive'),
        ),
        isTrue,
      );
      store.dispose();
    }, createHttpClient: Offline().createHttpClient);
  });

  test(
    'legacy data migrates once and a deliberately empty database stays empty',
    () async {
      final memory = MemoryStorageService();
      final old = AppStore(storage: memory);
      await old.load();
      await old.toggleFavorite('magnum');
      repository = FinanceRepository(
        openBox: () => Hive.openBox<dynamic>('finance'),
        readLegacy: () async => memory.value,
      );
      final migrated = AppStore(storage: repository);
      await migrated.load();
      expect(migrated.entry('magnum')!.favorite, isTrue);
      for (final entry in List.of(migrated.accessibleEntries)) {
        await migrated.deleteEntry(entry.id);
      }
      await repository.close();
      repository = FinanceRepository(
        openBox: () => Hive.openBox<dynamic>('finance'),
        readLegacy: () async => throw StateError('Migration must not rerun'),
      );
      final reopened = AppStore(storage: repository);
      await reopened.load();
      expect(reopened.storageError, isNull);
      expect(reopened.visibleEntries, isEmpty);
      old.dispose();
      migrated.dispose();
      reopened.dispose();
    },
  );

  test(
    'unreadable state is preserved rather than replaced by demo writes',
    () async {
      final box = await Hive.openBox<dynamic>('finance');
      await box.put('state', {'schema': 999, 'original': 'keep'});
      final store = AppStore(storage: repository);
      await store.load();
      expect(store.storageError, isNotNull);
      await store.toggleFavorite('magnum');
      expect((box.get('state') as Map)['original'], 'keep');
      await store.resetDemo();
      expect(store.storageError, isNull);
      expect((box.get('state') as Map)['schema'], 2);
      store.dispose();
    },
  );

  test(
    'repository rejects invalid references without overwriting committed data',
    () async {
      final store = AppStore(storage: repository);
      await store.load();
      final good = await repository.read();
      final bad = jsonDecode(good!) as Map<String, dynamic>;
      (bad['entries'] as List).first['familyId'] = 'missing';
      await expectLater(
        repository.write(jsonEncode(bad)),
        throwsFormatException,
      );
      expect(await repository.read(), good);
      store.dispose();
    },
  );

  test('combined query filters and sorting are deterministic and do not mutate data', () {
    final store = AppStore(storage: MemoryStorageService());
    final source = store.visibleEntries;
    final filtered = const EntryQuery(
      category: 'Азық-түлік',
      income: false,
      sort: EntrySort.amountHigh,
    ).apply(source);
    expect(filtered.map((e) => e.amount), [45000, 5000]);
    expect(const EntryQuery(text: 'MAGNUM').apply(source).single.id, 'magnum');
    expect(const EntryQuery(text: 'zzzz').apply(source), isEmpty);
    expect(const EntryQuery(income: true).apply(source).single.id, 'salary');
    expect(
      const EntryQuery(sort: EntrySort.amountLow).apply(source).first.id,
      'transport',
    );
    expect(
      const EntryQuery(sort: EntrySort.oldest).apply(source).first.id,
      'other',
    );
    final byTitle = const EntryQuery(sort: EntrySort.title).apply(source);
    for (var i = 1; i < byTitle.length; i++) {
      expect(
        byTitle[i - 1].title.toLowerCase().compareTo(
          byTitle[i].title.toLowerCase(),
        ),
        lessThanOrEqualTo(0),
      );
    }
    expect(store.visibleEntries.map((e) => e.id), source.map((e) => e.id));
    store.dispose();
  });
}
