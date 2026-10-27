import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../features/family/models/family.dart';
import '../../features/family/models/family_member.dart';
import '../../features/transactions/models/money_entry.dart';
import '../../features/goals/models/savings_goal.dart';
import '../../features/reminders/models/payment_reminder.dart';
import 'storage_service.dart';

/// One Hive record holds a consistent aggregate of five related model types.
/// A single put commits the complete state, so lists cannot partially update.
class FinanceRepository implements StorageService {
  FinanceRepository({required this.openBox, this.readLegacy});
  final Future<Box<dynamic>> Function() openBox;
  final Future<String?> Function()? readLegacy;
  Box<dynamic>? _box;
  static const boxName = 'otbasy_finance_v2';

  factory FinanceRepository.local() => FinanceRepository(
    openBox: () async {
      await Hive.initFlutter();
      return Hive.openBox<dynamic>(boxName);
    },
    readLegacy: LocalStorageService().read,
  );

  Future<Box<dynamic>> _database() async => _box ??= await openBox();

  Map<String, dynamic> _validate(Map<String, dynamic> data) {
    if (data['version'] != 1) {
      throw const FormatException('Unsupported version');
    }
    final entries = (data['entries'] as List)
        .map((e) => MoneyEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final goals = (data['goals'] as List)
        .map((e) => SavingsGoal.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final reminders = (data['reminders'] as List)
        .map(
          (e) => PaymentReminder.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
    final family = Family(id: 'family-main', name: data['family'] as String);
    final names = <String>{
      'Данияр',
      'Жансая',
      'Мирас',
      'Нұрсұлтан',
      ...entries.map((e) => e.owner),
      ...goals.map((g) => g.owner),
      ...goals.expand((g) => g.contributions.keys),
    };
    final members = names
        .map(
          (name) => FamilyMember(
            id: FamilyMember.idForName(name),
            familyId: family.id,
            name: name,
          ),
        )
        .toList();
    if (entries.any((e) => e.familyId != family.id || e.amount <= 0) ||
        goals.any((g) => g.familyId != family.id || g.target <= 0) ||
        reminders.any((r) => r.familyId != family.id)) {
      throw const FormatException('Invalid family reference or amount');
    }
    for (final ids in [
      entries.map((e) => e.id),
      goals.map((g) => g.id),
      reminders.map((r) => r.id),
    ]) {
      if (ids.toSet().length != ids.length || ids.any((id) => id.isEmpty)) {
        throw const FormatException('Duplicate or empty ID');
      }
    }
    if (data['largeText'] is! bool || data['notifications'] is! bool) {
      throw const FormatException('Invalid settings');
    }
    return {
      ...data,
      'schema': 2,
      'families': [family.toJson()],
      'members': members.map((m) => m.toJson()).toList(),
      'entries': entries.map((e) => e.toJson()).toList(),
      'goals': goals.map((g) => g.toJson()).toList(),
      'reminders': reminders.map((r) => r.toJson()).toList(),
    };
  }

  @override
  Future<String?> read() async {
    final box = await _database();
    final state = box.get('state');
    if (state != null) {
      final data = Map<String, dynamic>.from(state as Map);
      if (data['schema'] != 2) throw const FormatException('Unknown schema');
      return jsonEncode(_validate(data));
    }
    final legacy = await readLegacy?.call();
    if (legacy != null) {
      await write(legacy); // Keep the original preferences as a fallback copy.
      return read();
    }
    return null;
  }

  @override
  Future<void> write(String value) async {
    final data = _validate(jsonDecode(value) as Map<String, dynamic>);
    await (await _database()).put('state', data);
    await (await _database()).flush();
  }

  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}
