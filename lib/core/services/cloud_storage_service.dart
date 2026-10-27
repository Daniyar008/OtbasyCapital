import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'finance_cloud.dart';
import 'finance_repository.dart';
import 'storage_service.dart';

/// Save to account-specific Hive first, then send to PostgreSQL over HTTPS.
/// Failed uploads remain durable and retry on next save, login or manual refresh.
class CloudStorageService extends ChangeNotifier implements StorageService {
  CloudStorageService({required this.backend, required this.storageForAccount});
  final FinanceCloud backend;
  final StorageService Function(String userId) storageForAccount;
  String? cloudError;
  Object? lastError;
  StackTrace? lastErrorStack;
  bool syncing = false;
  DateTime? lastSynced;

  factory CloudStorageService.local(FinanceCloud backend) {
    final stores = <String, StorageService>{};
    return CloudStorageService(
      backend: backend,
      storageForAccount: (id) => stores.putIfAbsent(
        id,
        () => FinanceRepository(
          openBox: () => Hive.openBox<dynamic>('otbasy_cloud_$id'),
        ),
      ),
    );
  }

  String _userId() {
    final id = backend.account?.id;
    if (id == null) throw StateError('Sign in before accessing account data');
    return id;
  }

  Map<String, dynamic> _decode(String text) =>
      jsonDecode(text) as Map<String, dynamic>;

  @override
  Future<String?> read() async {
    final id = _userId();
    final local = storageForAccount(id);
    var raw = await local.read();
    // A damaged local file must not be silently replaced by remote data.
    final state = raw == null ? null : _decode(raw);
    syncing = true;
    notifyListeners();
    try {
      if (state?['cloudDirty'] == true) {
        await _push(id, state!, local);
        raw = await local.read();
      }
      final remote = await backend.download(id);
      if (backend.account?.id != id) throw StateError('Account changed');
      if (remote != null) {
        final merged = {
          ...remote,
          'largeText': state?['largeText'] ?? remote['largeText'],
          'notifications': state?['notifications'] ?? remote['notifications'],
          'cloudDirty': false,
          'cloudDeleted_entries': [],
          'cloudDeleted_goals': [],
          'cloudDeleted_reminders': [],
          'cloudPending_entries': [],
          'cloudPending_goals': [],
          'cloudPending_reminders': [],
        };
        await local.write(jsonEncode(merged));
        raw = await local.read();
      }
      cloudError = null;
      lastError = null;
      lastSynced = DateTime.now();
    } catch (error, stack) {
      lastError = error;
      lastErrorStack = stack;
      cloudError =
          'Бұлтқа қосылу мүмкін болмады. Жергілікті деректер ашылды. '
          'Интернетті тексеріп, «Қайта синхрондау» түймесін басыңыз.';
    } finally {
      syncing = false;
      notifyListeners();
    }
    if (raw == null && cloudError != null) {
      throw StateError('No account cache and cloud download failed');
    }
    return raw;
  }

  @override
  Future<void> write(String value) async {
    final id = _userId();
    final local = storageForAccount(id);
    final before = await local.read();
    final old = before == null ? <String, dynamic>{} : _decode(before);
    final next = _decode(value);
    for (final type in ['entries', 'goals', 'reminders']) {
      final currentIds = (next[type] as List)
          .map((r) => (r as Map)['id'])
          .toSet();
      final previousIds = (old[type] as List? ?? [])
          .map((r) => (r as Map)['id'])
          .toSet();
      next['cloudDeleted_$type'] = {
        ...(old['cloudDeleted_$type'] as List? ?? []),
        ...previousIds.difference(currentIds),
      }.difference(currentIds).toList();
      final previousById = {
        for (final row in old[type] as List? ?? [])
          (row as Map)['id']: jsonEncode(row),
      };
      next['cloudPending_$type'] = {
        ...(old['cloudPending_$type'] as List? ?? []),
        for (final row in next[type] as List)
          if (previousById[(row as Map)['id']] != jsonEncode(row)) row['id'],
      }.intersection(currentIds).toList();
    }
    next['cloudDirty'] = true;
    await local.write(jsonEncode(next));
    syncing = true;
    notifyListeners();
    try {
      await _push(id, next, local);
      cloudError = null;
      lastError = null;
      lastSynced = DateTime.now();
    } catch (error, stack) {
      lastError = error;
      lastErrorStack = stack;
      cloudError =
          'Құрылғыда сақталды. Бұлт әлі жаңартылмады. '
          'Интернетті тексеріп, «Қайта синхрондау» түймесін басыңыз.';
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  Future<void> _push(
    String id,
    Map<String, dynamic> state,
    StorageService local,
  ) async {
    if (backend.account?.id != id) throw StateError('Account changed');
    await backend.upload(id, state);
    if (backend.account?.id != id) throw StateError('Account changed');
    await local.write(
      jsonEncode({
        ...state,
        'cloudDirty': false,
        'cloudDeleted_entries': [],
        'cloudDeleted_goals': [],
        'cloudDeleted_reminders': [],
        'cloudPending_entries': [],
        'cloudPending_goals': [],
        'cloudPending_reminders': [],
      }),
    );
  }
}
