import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otbasy_capital/app/app_store.dart';
import 'package:otbasy_capital/core/services/cloud_storage_service.dart';
import 'package:otbasy_capital/core/services/storage_service.dart';
import 'package:otbasy_capital/core/services/supabase_finance_service.dart';
import 'package:otbasy_capital/features/transactions/models/money_entry.dart';

const uid = '00000000-0000-4000-8000-000000000001';
Map<String, dynamic> get user => {
  'id': uid,
  'email': 'test@example.com',
  'aud': 'authenticated',
  'role': 'authenticated',
  'created_at': '2026-10-27T00:00:00Z',
  'app_metadata': {'provider': 'email'},
  'user_metadata': {'name': 'Данияр'},
};
String jwt() {
  String enc(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${enc({'alg': 'HS256', 'typ': 'JWT'})}.'
      '${enc({'sub': uid, 'role': 'authenticated', 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.'
      '${base64Url.encode(utf8.encode('test-signature')).replaceAll('=', '')}';
}

void main() {
  test(
    'real SDK sends GET POST PATCH DELETE and refreshes the operation model',
    () async {
      final calls = <http.Request>[];
      final tables = <String, List<Map<String, dynamic>>>{};
      final transport = MockClient((request) async {
        calls.add(request);
        final path = request.url.path;
        if (path == '/auth/v1/token') {
          expect(request.url.queryParameters['grant_type'], 'password');
          expect(jsonDecode(request.body)['email'], 'test@example.com');
          return http.Response(
            jsonEncode({
              'access_token': jwt(),
              'refresh_token': 'test-refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': user,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (!path.startsWith('/rest/v1/')) return http.Response('{}', 404);
        expect(request.headers['authorization'], startsWith('Bearer '));
        final table = path.split('/').last;
        if (request.method == 'POST') {
          expect(
            request.url.queryParameters['on_conflict'],
            table == 'otbasy_entries' ? isNull : 'user_id,id',
          );
          final body = jsonDecode(request.body);
          final rows = body is List
              ? body.cast<Map<String, dynamic>>()
              : [body as Map<String, dynamic>];
          for (final row in rows) {
            expect(row['user_id'], uid);
            if (table != 'otbasy_families') {
              expect(row['family_id'], 'family-main');
            }
            final current = tables.putIfAbsent(table, () => []);
            current.removeWhere((r) => r['id'] == row['id']);
            current.add(row);
          }
          return http.Response('', 201, request: request);
        }
        expect(request.url.queryParameters['user_id'], 'eq.$uid');
        if (request.method == 'PATCH') {
          expect(table, 'otbasy_entries');
          expect(request.url.queryParameters['id'], 'eq.entry-1');
          expect(request.url.queryParameters['family_id'], 'eq.family-main');
          final values = jsonDecode(request.body) as Map<String, dynamic>;
          expect(values.containsKey('user_id'), isFalse);
          expect(values.containsKey('id'), isFalse);
          final row = tables[table]!.single;
          row.addAll(values);
          return http.Response(
            jsonEncode([row]),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'DELETE') {
          expect(table, 'otbasy_entries');
          expect(request.url.queryParameters['family_id'], 'eq.family-main');
          expect(request.url.queryParameters['id'], contains('entry-1'));
          tables[table]!.removeWhere((row) => row['id'] == 'entry-1');
          return http.Response('', 204, request: request);
        }
        return http.Response(
          jsonEncode(tables[table] ?? []),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      });
      final client = SupabaseClient(
        'https://test.supabase.co',
        'public-test-key',
        httpClient: transport,
        authOptions: const AuthClientOptions(
          autoRefreshToken: false,
          authFlowType: AuthFlowType.implicit,
        ),
      );
      final backend = SupabaseFinanceService(client);
      final cloud = CloudStorageService(
        backend: backend,
        storageForAccount: (() {
          final stores = <String, MemoryStorageService>{};
          return (String id) =>
              stores.putIfAbsent(id, MemoryStorageService.new);
        })(),
      );
      final store = AppStore(storage: cloud, cloud: cloud);
      try {
        await store.login('test@example.com', 'Valid2026');
        expect(store.signedIn, isTrue);
        expect(
          store.cloudError,
          isNull,
          reason: '${cloud.lastError}\n${cloud.lastErrorStack}',
        );
        MoneyEntry operation(int amount) => MoneyEntry(
          id: 'entry-1',
          title: 'Дәріхана',
          amount: amount,
          income: false,
          category: 'Басқа',
          date: DateTime(2026, 10, 27),
          owner: 'Данияр',
        );
        await store.saveEntry(operation(2000));
        expect(store.cloudError, isNull);
        var row = tables['otbasy_entries']!.single;
        expect(row['title'], 'Дәріхана');
        expect(row['amount'], 2000);
        expect(row['entry_date'], startsWith('2026-10-27'));
        expect(
          tables['otbasy_members']!.map((r) => r['id']),
          contains(row['owner_id']),
        );
        await store.saveEntry(operation(3500));
        row = tables['otbasy_entries']!.single;
        expect(row['amount'], 3500);
        await store.toggleFavorite('entry-1');
        expect(tables['otbasy_entries']!.single['favorite'], isTrue);
        final writesBeforeRefresh = calls
            .where((r) => r.method == 'POST')
            .length;
        await store.syncCloud();
        expect(store.entry('entry-1')!.amount, 3500);
        expect(
          calls.where((r) => r.method == 'POST').length,
          writesBeforeRefresh,
        );
        await store.deleteEntry('entry-1');
        expect(tables['otbasy_entries'], isEmpty);
        expect(calls.where((r) => r.method == 'DELETE'), hasLength(1));
        final entryCalls = calls.where(
          (r) => r.url.path == '/rest/v1/otbasy_entries',
        );
        expect(entryCalls.where((r) => r.method == 'POST'), hasLength(1));
        expect(entryCalls.where((r) => r.method == 'PATCH'), hasLength(2));
        expect(entryCalls.any((r) => r.method == 'GET'), isTrue);
      } finally {
        store.dispose();
        cloud.dispose();
        await client.dispose();
      }
    },
  );

  test('signup submits name metadata and requires confirmation when server returns no session', () async {
    final client = SupabaseClient(
      'https://test.supabase.co',
      'public-test-key',
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
      httpClient: MockClient((request) async {
        expect(request.url.path, '/auth/v1/signup');
        final body = jsonDecode(request.body) as Map;
        expect(body['email'], 'test@example.com');
        expect(body['data']['name'], 'Данияр');
        return http.Response(
          jsonEncode(user),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    try {
      final backend = SupabaseFinanceService(client);
      expect(
        await backend.signUp('test@example.com', 'Valid2026', 'Данияр'),
        isFalse,
      );
      expect(backend.account, isNull);
    } finally {
      await client.dispose();
    }
  });
}
