import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/services/storage_service.dart';
import '../core/services/cloud_storage_service.dart';
import '../features/transactions/models/money_entry.dart';
import '../features/goals/models/savings_goal.dart';
import '../features/reminders/models/payment_reminder.dart';

class AppStore extends ChangeNotifier {
  AppStore({required this.storage, this.cloud}) {
    _seed();
    cloud?.addListener(notifyListeners);
  }
  final StorageService storage;
  final CloudStorageService? cloud;
  bool get cloudEnabled => cloud != null;
  String? get cloudError => cloud?.cloudError;
  Future<void>? _cloudRefresh;
  bool get syncing => _cloudRefresh != null || (cloud?.syncing ?? false);

  Future<void> login(String email, String password) async {
    if (cloud == null) {
      signIn(email);
      return;
    }
    await _cloudRefresh;
    await _pendingWrite;
    await cloud!.backend.signIn(email, password);
    await restoreCloudAccount();
  }

  Future<bool> register(String email, String password, String name) async {
    if (cloud == null) {
      signIn(email, name: name);
      return true;
    }
    await _cloudRefresh;
    await _pendingWrite;
    final ready = await cloud!.backend.signUp(email, password, name);
    if (ready) await restoreCloudAccount();
    return ready;
  }

  void _emptyCloudAccount() {
    _seed();
    _entries = [];
    _goals = [];
    _reminders = [];
    final account = cloud!.backend.account!;
    name = account.name;
    email = account.email;
    family = '${account.name} отбасы';
    final now = DateTime.now();
    period = DateTime(now.year, now.month);
  }

  Future<void> restoreCloudAccount() async {
    if (cloud?.backend.account == null) return;
    _emptyCloudAccount();
    await load();
    name = cloud!.backend.account!.name;
    email = cloud!.backend.account!.email;
    signedIn = true;
    notifyListeners();
  }

  Future<void> syncCloud() => _cloudRefresh ??= _refreshCloud().whenComplete(
    () => _cloudRefresh = null,
  );

  Future<void> _refreshCloud() async {
    await _pendingWrite;
    await load();
  }

  Future<void> logout() async {
    await _cloudRefresh;
    await _pendingWrite;
    if (cloud != null) {
      await cloud!.backend.signOut();
      _seed();
      _entries = [];
      _goals = [];
      _reminders = [];
      name = '';
      email = '';
      family = '';
    }
    signOut();
  }

  @override
  void dispose() {
    cloud?.removeListener(notifyListeners);
    super.dispose();
  }

  bool signedIn = false;
  String name = 'Данияр',
      email = 'daniyar@example.com',
      family = 'Сұлтангереевтер';
  bool sharedView = true, largeText = false, notifications = true;
  String? storageError;
  bool _loadFailed = false;
  DateTime period = DateTime(2026, 10);
  List<MoneyEntry> _entries = [];
  List<SavingsGoal> _goals = [];
  List<PaymentReminder> _reminders = [];
  Future<void> _pendingWrite = Future.value();
  static const categories = ['Азық-түлік', 'Көлік', 'Үй төлемдері', 'Басқа'];
  static const limits = {
    'Азық-түлік': 60000,
    'Көлік': 35000,
    'Үй төлемдері': 60000,
    'Басқа': 45000,
  };

  List<MoneyEntry> get accessibleEntries =>
      _entries.where((e) => e.shared || e.owner == name).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  List<MoneyEntry> get visibleEntries => accessibleEntries
      .where(
        (e) =>
            e.shared == sharedView &&
            e.date.year == period.year &&
            e.date.month == period.month,
      )
      .toList();
  List<SavingsGoal> get goals =>
      List.unmodifiable(_goals.where((g) => g.shared || g.owner == name));
  List<PaymentReminder> get reminders => List.unmodifiable(_reminders);
  int get income =>
      visibleEntries.where((e) => e.income).fold(0, (sum, e) => sum + e.amount);
  int get expense => visibleEntries
      .where((e) => !e.income)
      .fold(0, (sum, e) => sum + e.amount);
  int get balance => income - expense;
  int categoryExpense(String category) => visibleEntries
      .where((e) => !e.income && e.category == category)
      .fold(0, (sum, e) => sum + e.amount);
  MoneyEntry? entry(String id) {
    for (final item in accessibleEntries) {
      if (item.id == id) return item;
    }
    return null;
  }

  SavingsGoal? goal(String id) {
    for (final item in goals) {
      if (item.id == id) return item;
    }
    return null;
  }

  String newId() => DateTime.now().microsecondsSinceEpoch.toString();
  void signIn(String email, {String? name}) {
    if (cloud != null) throw StateError('Use Supabase login');
    this.email = email.trim();
    if (name != null && name.trim().isNotEmpty) this.name = name.trim();
    signedIn = true;
    notifyListeners();
  }

  void signOut() {
    signedIn = false;
    notifyListeners();
  }

  void selectView(bool shared) {
    sharedView = shared;
    notifyListeners();
  }

  void setPeriod(DateTime value) {
    period = DateTime(value.year, value.month);
    notifyListeners();
  }

  Future<void> setFamily(String value) async {
    await _cloudRefresh;
    family = value.trim();
    await _changed();
  }

  Future<void> saveEntry(MoneyEntry value) async {
    await _cloudRefresh;
    if (value.amount <= 0 || value.title.trim().isEmpty) {
      throw ArgumentError('Invalid operation');
    }
    final index = _entries.indexWhere((e) => e.id == value.id);
    if (index < 0) {
      _entries.add(value);
    } else {
      _entries[index] = value;
    }
    sharedView = value.shared;
    period = DateTime(value.date.year, value.date.month);
    await _changed();
  }

  Future<void> deleteEntry(String id) async {
    await _cloudRefresh;
    _entries.removeWhere((e) => e.id == id);
    await _changed();
  }

  Future<void> toggleFavorite(String id) async {
    await _cloudRefresh;
    final index = _entries.indexWhere((e) => e.id == id);
    if (index >= 0) {
      _entries[index] = _entries[index].copyWith(
        favorite: !_entries[index].favorite,
      );
    }
    await _changed();
  }

  Future<void> addGoal(SavingsGoal value) async {
    await _cloudRefresh;
    if (value.target <= 0 || value.title.trim().isEmpty) {
      throw ArgumentError('Invalid goal');
    }
    _goals.add(value);
    await _changed();
  }

  Future<void> contribute(String id, int amount) async {
    await _cloudRefresh;
    if (amount <= 0) throw ArgumentError('Invalid contribution');
    final index = _goals.indexWhere((e) => e.id == id);
    if (index < 0) throw StateError('Goal not found');
    _goals[index] = _goals[index].contribute(name, amount);
    await _changed();
  }

  Future<void> addReminder(PaymentReminder value) async {
    await _cloudRefresh;
    _reminders.add(value);
    await _changed();
  }

  Future<void> toggleReminder(String id) async {
    await _cloudRefresh;
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index >= 0) _reminders[index] = _reminders[index].toggle();
    await _changed();
  }

  Future<void> setSettings({
    required bool largeText,
    required bool notifications,
  }) async {
    await _cloudRefresh;
    this.largeText = largeText;
    this.notifications = notifications;
    await _changed();
  }

  Future<void> resetDemo() async {
    await _cloudRefresh;
    _seed();
    _loadFailed = false;
    await _changed();
  }

  Future<void> load() async {
    try {
      final raw = await storage.read();
      if (raw == null) {
        if (cloud != null) _emptyCloudAccount();
        _loadFailed = false;
        await _changed();
        return;
      }
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['version'] != 1) {
        throw const FormatException('Unsupported data version');
      }
      final entries = (json['entries'] as List)
          .map((e) => MoneyEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final goals = (json['goals'] as List)
          .map((e) => SavingsGoal.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final reminders = (json['reminders'] as List)
          .map(
            (e) =>
                PaymentReminder.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      _entries = entries;
      _goals = goals;
      _reminders = reminders;
      family = json['family'] as String;
      name = json['profileName'] as String? ?? name;
      email = json['profileEmail'] as String? ?? email;
      largeText = json['largeText'] as bool;
      notifications = json['notifications'] as bool;
      storageError = null;
      _loadFailed = false;
    } catch (_) {
      if (cloud != null) {
        _emptyCloudAccount();
      } else {
        _seed();
      }
      _loadFailed = true;
      storageError = 'Деректер қорын оқу мүмкін болмады. Оқу мысалы ашылды, сақтау бұғатталды. Қайта іске қосыңыз немесе баптаулардан оқу деректерін қалпына келтіріңіз.';
    }
    notifyListeners();
  }

  Future<void> _changed() async {
    notifyListeners();
    if (_loadFailed) return;
    final snapshot = jsonEncode({
      'version': 1,
      'family': family,
      'profileName': name,
      'profileEmail': email,
      'largeText': largeText,
      'notifications': notifications,
      'entries': _entries.map((e) => e.toJson()).toList(),
      'goals': _goals.map((e) => e.toJson()).toList(),
      'reminders': _reminders.map((e) => e.toJson()).toList(),
    });
    _pendingWrite = _pendingWrite.then((_) async {
      try {
        await storage.write(snapshot);
        if (storageError != null) {
          storageError = null;
          notifyListeners();
        }
      } catch (_) {
        storageError =
            'Өзгеріс осы сессияда бар, бірақ құрылғыға сақтау мүмкін болмады.';
        notifyListeners();
      }
    });
    await _pendingWrite;
  }

  void _seed() {
    _entries = [
      MoneyEntry(
        id: 'magnum',
        title: 'Magnum',
        amount: 5000,
        income: false,
        category: 'Азық-түлік',
        date: DateTime(2026, 10, 16, 12),
        owner: 'Данияр',
        note: 'Апталық сатып алу',
      ),
      MoneyEntry(
        id: 'transport',
        title: 'Қоғамдық көлік',
        amount: 1200,
        income: false,
        category: 'Көлік',
        date: DateTime(2026, 10, 16, 9),
        owner: 'Мирас',
      ),
      MoneyEntry(
        id: 'salary',
        title: 'Жалақы',
        amount: 350000,
        income: true,
        category: 'Кіріс',
        date: DateTime(2026, 10, 15),
        owner: 'Жансая',
      ),
      MoneyEntry(
        id: 'food-month',
        title: 'Азық-түлік сатып алу',
        amount: 45000,
        income: false,
        category: 'Азық-түлік',
        date: DateTime(2026, 10, 12),
        owner: 'Жансая',
      ),
      MoneyEntry(
        id: 'travel',
        title: 'Жол шығындары',
        amount: 18800,
        income: false,
        category: 'Көлік',
        date: DateTime(2026, 10, 11),
        owner: 'Мирас',
      ),
      MoneyEntry(
        id: 'utilities',
        title: 'Коммуналдық төлем',
        amount: 35000,
        income: false,
        category: 'Үй төлемдері',
        date: DateTime(2026, 10, 10),
        owner: 'Жансая',
      ),
      MoneyEntry(
        id: 'other',
        title: 'Басқа шығындар',
        amount: 20000,
        income: false,
        category: 'Басқа',
        date: DateTime(2026, 10, 9),
        owner: 'Данияр',
      ),
    ];
    _goals = [
      SavingsGoal(
        id: 'holiday',
        title: 'Отбасылық демалыс',
        target: 500000,
        date: DateTime(2027, 7, 1),
        contributions: {'Жансая': 70000, 'Мирас': 60000, 'Данияр': 20000},
      ),
      SavingsGoal(
        id: 'laptop',
        title: 'Жаңа ноутбук',
        target: 400000,
        date: DateTime(2027, 2, 1),
        contributions: {'Данияр': 120000},
        shared: false,
      ),
    ];
    _reminders = [
      PaymentReminder(
        id: 'utilities',
        title: 'Коммуналдық қызметтер',
        date: DateTime(2026, 10, 25),
      ),
      PaymentReminder(
        id: 'internet',
        title: 'Интернет төлемі',
        date: DateTime(2026, 10, 28),
      ),
    ];
    sharedView = true;
    period = DateTime(2026, 10);
    storageError = null;
  }
}
