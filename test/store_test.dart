import 'package:flutter_test/flutter_test.dart';
import 'package:otbasy_capital/app/app_store.dart';
import 'package:otbasy_capital/core/services/storage_service.dart';
import 'package:otbasy_capital/core/utils/validators.dart';
import 'package:otbasy_capital/features/transactions/models/money_entry.dart';

void main() {
  test('add edit delete recalculate totals and survive reopening', () async {
    final storage = MemoryStorageService();
    final store = AppStore(storage: storage);
    expect(store.balance, 225000);
    await store.saveEntry(
      MoneyEntry(
        id: 'test',
        title: 'Базар',
        amount: 2000,
        income: false,
        category: 'Азық-түлік',
        date: DateTime(2026, 10, 20),
        owner: 'Данияр',
      ),
    );
    expect(store.balance, 223000);
    await store.saveEntry(
      MoneyEntry(
        id: 'magnum',
        title: 'Magnum',
        amount: 4000,
        income: false,
        category: 'Азық-түлік',
        date: DateTime(2026, 10, 16),
        owner: 'Данияр',
      ),
    );
    expect(store.balance, 224000);
    await store.deleteEntry('test');
    expect(store.balance, 226000);
    await store.toggleFavorite('magnum');
    final reopened = AppStore(storage: storage);
    await reopened.load();
    expect(reopened.balance, 226000);
    expect(reopened.entry('magnum')!.favorite, isTrue);
    store.dispose();
    reopened.dispose();
  });
  test('private entries and private goals are scoped to their owner', () async {
    final store = AppStore(storage: MemoryStorageService());
    await store.saveEntry(
      MoneyEntry(
        id: 'private',
        title: 'Жеке',
        amount: 700,
        income: false,
        category: 'Басқа',
        date: DateTime(2026, 10, 20),
        owner: 'Жансая',
        shared: false,
      ),
    );
    expect(store.entry('private'), isNull);
    expect(store.balance, 0);
    store.signIn('zhansaya@example.com', name: 'Жансая');
    expect(store.entry('private'), isNotNull);
    expect(store.balance, -700);
    expect(store.goal('laptop'), isNull);
    store.selectView(true);
    expect(store.balance, 225000);
    store.dispose();
  });
  test(
    'goal contributions and settings persist without changing the ledger',
    () async {
      final storage = MemoryStorageService();
      final persistent = AppStore(storage: storage);
      await persistent.contribute('holiday', 10000);
      await persistent.setSettings(largeText: true, notifications: false);
      final reopened = AppStore(storage: storage);
      await reopened.load();
      expect(reopened.goal('holiday')!.saved, 160000);
      expect(reopened.balance, 225000);
      expect(reopened.largeText, isTrue);
      expect(reopened.notifications, isFalse);
      persistent.dispose();
      reopened.dispose();
    },
  );
  test(
    'malformed saved data opens a usable demonstration with an error notice',
    () async {
      final storage = MemoryStorageService()..value = '{broken';
      final store = AppStore(storage: storage);
      await store.load();
      expect(store.balance, 225000);
      expect(store.storageError, isNotNull);
      store.dispose();
    },
  );
  test('form validators reject blank and invalid input', () {
    for (final email in ['', 'a', 'x@', 'a b@example.com']) {
      expect(Validators.email(email), isNotNull);
    }
    expect(Validators.email('daniyar@example.com'), isNull);
    expect(Validators.password(''), isNotNull);
    expect(Validators.newPassword('abcdefgh'), isNotNull);
    expect(Validators.newPassword('Demo2026'), isNull);
    for (final amount in ['', '0', '-4', 'NaN', '1000000001']) {
      expect(Validators.amount(amount), isNotNull);
    }
    expect(Validators.amount('4000'), isNull);
  });
}
