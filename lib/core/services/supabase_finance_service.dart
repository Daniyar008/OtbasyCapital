import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/family/models/family_member.dart';
import 'finance_cloud.dart';

/// These SDK calls send HTTPS to Supabase Auth and the PostgREST Data API.
/// PostgreSQL credentials and SQL strings are never sent by the Flutter app.
class SupabaseFinanceService implements FinanceCloud {
  SupabaseFinanceService(this.client);
  final SupabaseClient client;

  @override
  CloudAccount? get account {
    final user = client.auth.currentUser;
    if (user == null) return null;
    return CloudAccount(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['name'] as String? ?? 'Пайдаланушы',
    );
  }

  @override
  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<bool> signUp(String email, String password, String name) async {
    final response = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'name': name.trim()},
    );
    return response.session != null;
  }

  @override
  Future<void> signOut() => client.auth.signOut(scope: SignOutScope.local);

  void _requireAccount(String id) {
    if (account?.id != id) throw StateError('Account changed during sync');
  }

  Future<List<Map<String, dynamic>>> _rows(String table, String id) async {
    _requireAccount(id);
    final rows = await client
        .from(table)
        .select()
        .eq('user_id', id)
        .eq('family_id', 'family-main');
    _requireAccount(id);
    return rows;
  }

  /// GET /rest/v1/otbasy_entries, scoped to the authenticated account.
  Future<List<Map<String, dynamic>>> getEntries(String userId) =>
      _rows('otbasy_entries', userId);

  /// POST creates a new operation. ID/user_id are supplied by our model mapper.
  Future<void> createEntry(String userId, Map<String, dynamic> row) async {
    _requireAccount(userId);
    if (row['user_id'] != userId) throw StateError('Invalid owner');
    await client.from('otbasy_entries').insert(row);
    _requireAccount(userId);
  }

  /// PATCH changes an existing operation without changing its identity.
  Future<void> updateEntry(String userId, Map<String, dynamic> row) async {
    _requireAccount(userId);
    if (row['user_id'] != userId) throw StateError('Invalid owner');
    final values = Map<String, dynamic>.from(row)
      ..remove('id')
      ..remove('user_id');
    final updated = await client
        .from('otbasy_entries')
        .update(values)
        .eq('user_id', userId)
        .eq('family_id', 'family-main')
        .eq('id', row['id'] as String)
        .select('id');
    _requireAccount(userId);
    if (updated.length != 1) {
      throw StateError('Operation was removed; retry sync');
    }
  }

  /// DELETE removes only explicit IDs in the current account.
  Future<void> deleteEntries(String userId, List<String> ids) async {
    if (ids.isEmpty) return;
    _requireAccount(userId);
    await client
        .from('otbasy_entries')
        .delete()
        .eq('user_id', userId)
        .eq('family_id', 'family-main')
        .inFilter('id', ids);
    _requireAccount(userId);
  }

  Future<void> _writeEntries(
    String userId,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return;
    _requireAccount(userId);
    final existing = await client
        .from('otbasy_entries')
        .select('id')
        .eq('user_id', userId)
        .eq('family_id', 'family-main')
        .inFilter('id', rows.map((row) => row['id'] as String).toList());
    _requireAccount(userId);
    final ids = existing.map((row) => row['id']).toSet();
    for (final row in rows) {
      if (ids.contains(row['id'])) {
        await updateEntry(userId, row);
      } else {
        await createEntry(userId, row);
      }
    }
  }

  @override
  Future<Map<String, dynamic>?> download(String userId) async {
    _requireAccount(userId);
    final families = await client
        .from('otbasy_families')
        .select()
        .eq('user_id', userId)
        .eq('id', 'family-main');
    _requireAccount(userId);
    if (families.isEmpty) return null;
    final entries = await getEntries(userId);
    final goals = await _rows('otbasy_goals', userId);
    final reminders = await _rows('otbasy_reminders', userId);
    return {
      'version': 1,
      'family': families.single['name'],
      'profileName': account!.name,
      'profileEmail': account!.email,
      'largeText': false,
      'notifications': true,
      'entries': entries
          .map(
            (r) => {
              'id': r['id'],
              'familyId': r['family_id'],
              'title': r['title'],
              'amount': r['amount'],
              'income': r['income'],
              'category': r['category'],
              'date': r['entry_date'],
              'owner': r['owner_name'],
              'note': r['note'],
              'shared': r['shared'],
              'favorite': r['favorite'],
            },
          )
          .toList(),
      'goals': goals
          .map(
            (r) => {
              'id': r['id'],
              'familyId': r['family_id'],
              'title': r['title'],
              'target': r['target'],
              'date': r['target_date'],
              'owner': r['owner_name'],
              'shared': r['shared'],
              'contributions': r['contributions'],
            },
          )
          .toList(),
      'reminders': reminders
          .map(
            (r) => {
              'id': r['id'],
              'familyId': r['family_id'],
              'title': r['title'],
              'date': r['reminder_date'],
              'monthly': r['monthly'],
              'done': r['done'],
            },
          )
          .toList(),
    };
  }

  Future<void> _upsert(
    String table,
    String id,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return;
    _requireAccount(id);
    // INSERT ... ON CONFLICT (user_id, id) DO UPDATE, enforced by RLS.
    await client.from(table).upsert(rows, onConflict: 'user_id,id');
    _requireAccount(id);
  }

  @override
  Future<void> upload(String userId, Map<String, dynamic> state) async {
    _requireAccount(userId);
    final now = DateTime.now().toUtc().toIso8601String();
    Map<String, dynamic> base(String id) => {
      'user_id': userId,
      'id': id,
      'updated_at': now,
    };
    final entries = (state['entries'] as List).cast<Map>();
    final goals = (state['goals'] as List).cast<Map>();
    final reminders = (state['reminders'] as List).cast<Map>();
    List<Map> pending(String type, List<Map> rows) {
      final ids = (state['cloudPending_$type'] as List? ?? [])
          .cast<String>()
          .toSet();
      return rows.where((row) => ids.contains(row['id'])).toList();
    }

    await _upsert('otbasy_families', userId, [
      {...base('family-main'), 'name': state['family']},
    ]);
    final names = <String>{
      state['profileName'] as String,
      ...entries.map((r) => r['owner'] as String),
      ...goals.map((r) => r['owner'] as String),
      ...goals.expand((r) => (r['contributions'] as Map).keys.cast<String>()),
    };
    await _upsert(
      'otbasy_members',
      userId,
      names
          .map(
            (name) => {
              ...base(FamilyMember.idForName(name)),
              'family_id': 'family-main',
              'name': name,
            },
          )
          .toList(),
    );
    await _writeEntries(
      userId,
      pending('entries', entries)
          .map(
            (r) => {
              ...base(r['id'] as String),
              'family_id': r['familyId'],
              'owner_id': FamilyMember.idForName(r['owner'] as String),
              'title': r['title'],
              'amount': r['amount'],
              'income': r['income'],
              'category': r['category'],
              'entry_date': r['date'],
              'owner_name': r['owner'],
              'note': r['note'],
              'shared': r['shared'],
              'favorite': r['favorite'],
            },
          )
          .toList(),
    );
    await _upsert(
      'otbasy_goals',
      userId,
      pending('goals', goals)
          .map(
            (r) => {
              ...base(r['id'] as String),
              'family_id': r['familyId'],
              'owner_id': FamilyMember.idForName(r['owner'] as String),
              'title': r['title'],
              'target': r['target'],
              'target_date': r['date'],
              'owner_name': r['owner'],
              'shared': r['shared'],
              'contributions': r['contributions'],
            },
          )
          .toList(),
    );
    await _upsert(
      'otbasy_reminders',
      userId,
      pending('reminders', reminders)
          .map(
            (r) => {
              ...base(r['id'] as String),
              'family_id': r['familyId'],
              'title': r['title'],
              'reminder_date': r['date'],
              'monthly': r['monthly'],
              'done': r['done'],
            },
          )
          .toList(),
    );
    // Only explicit tombstones are deleted, never "all rows missing locally".
    for (final type in ['entries', 'goals', 'reminders']) {
      final ids = (state['cloudDeleted_$type'] as List? ?? []).cast<String>();
      if (ids.isEmpty) continue;
      if (type == 'entries') {
        await deleteEntries(userId, ids);
        continue;
      }
      _requireAccount(userId);
      await client
          .from('otbasy_$type')
          .delete()
          .eq('user_id', userId)
          .eq('family_id', 'family-main')
          .inFilter('id', ids);
      _requireAccount(userId);
    }
  }
}
