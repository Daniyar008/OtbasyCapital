import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otbasy_capital/core/services/supabase_finance_service.dart';
import 'package:otbasy_capital/core/services/sync_state.dart';

import 'supabase_service_test.dart' show uid, jwt, user;

void main() {
  late SupabaseClient client;
  late SupabaseFinanceService api;
  final calls = <http.Request>[];
  late Future<http.Response> Function(http.Request) handler;
  setUp(() async {
    calls.clear();
    handler = (r) async => http.Response(
      '[]',
      200,
      request: r,
      headers: {'content-type': 'application/json'},
    );
    client = SupabaseClient(
      'https://test.supabase.co',
      'public-test-key',
      postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
      httpClient: MockClient((request) async {
        if (request.url.path == '/auth/v1/token') {
          return http.Response(
            jsonEncode({
              'access_token': jwt(),
              'refresh_token': 'unit-refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': user,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        calls.add(request);
        return handler(request);
      }),
    );
    api = SupabaseFinanceService(client);
    await api.signIn('test@example.com', 'Valid2026');
  });
  tearDown(() async => client.dispose());

  Map<String, dynamic> operation() => {
    'id': 'operation-5',
    'user_id': uid,
    'family_id': 'family-main',
    'owner_id': 'member-unit',
    'title': 'Кітап',
    'amount': 4500,
    'income': false,
    'category': 'Басқа',
    'entry_date': '2026-10-27T00:00:00Z',
    'owner_name': 'Данияр',
    'shared': true,
    'favorite': false,
    'note': '',
  };

  test(
    'GET reads only the current user family and parses server JSON',
    () async {
      handler = (r) async => http.Response(
        jsonEncode([operation()]),
        200,
        request: r,
        headers: {'content-type': 'application/json'},
      );
      final rows = await api.getEntries(uid);
      expect(calls.single.method, 'GET');
      expect(calls.single.url.queryParameters['user_id'], 'eq.$uid');
      expect(calls.single.url.queryParameters['family_id'], 'eq.family-main');
      expect(rows.single['title'], 'Кітап');
      expect(rows.single['amount'], 4500);
    },
  );

  test('POST sends the new operation with owner and numeric amount', () async {
    handler = (r) async => http.Response('', 201, request: r);
    await api.createEntry(uid, operation());
    expect(calls.single.method, 'POST');
    expect(calls.single.url.path, '/rest/v1/otbasy_entries');
    final json = jsonDecode(calls.single.body) as Map;
    expect(json['user_id'], uid);
    expect(json['amount'], 4500);
  });

  test(
    'PATCH updates one operation without modifying its primary key',
    () async {
      handler = (r) async => http.Response(
        '[{"id":"operation-5"}]',
        200,
        request: r,
        headers: {'content-type': 'application/json'},
      );
      await api.updateEntry(uid, {...operation(), 'amount': 5500});
      expect(calls.single.method, 'PATCH');
      expect(calls.single.url.queryParameters['id'], 'eq.operation-5');
      expect(calls.single.url.queryParameters['user_id'], 'eq.$uid');
      final json = jsonDecode(calls.single.body) as Map;
      expect(json['amount'], 5500);
      expect(json.containsKey('user_id'), isFalse);
      expect(json.containsKey('id'), isFalse);
    },
  );

  test('DELETE targets explicit IDs and includes the account scope', () async {
    handler = (r) async => http.Response('', 204, request: r);
    await api.deleteEntries(uid, ['operation-5']);
    expect(calls.single.method, 'DELETE');
    expect(calls.single.url.queryParameters['user_id'], 'eq.$uid');
    expect(calls.single.url.queryParameters['id'], contains('operation-5'));
  });

  test('500 server response becomes a typed API error', () async {
    handler = (r) async => http.Response(
      '{"message":"server unavailable","code":"500"}',
      500,
      request: r,
      headers: {'content-type': 'application/json'},
    );
    try {
      await api.getEntries(uid);
      fail('HTTP 500 must not be treated as success');
    } on PostgrestException catch (error) {
      expect(classifySyncFailure(error), SyncFailure.server);
    }
  });

  test('timeout and unavailable network stay distinguishable', () async {
    handler = (_) =>
        Future<http.Response>.error(TimeoutException('request timeout'));
    await expectLater(api.getEntries(uid), throwsA(isA<TimeoutException>()));
    expect(
      classifySyncFailure(TimeoutException('timeout')),
      SyncFailure.timeout,
    );
    handler = (_) =>
        Future<http.Response>.error(http.ClientException('offline'));
    await expectLater(
      api.getEntries(uid),
      throwsA(isA<http.ClientException>()),
    );
    expect(
      classifySyncFailure(http.ClientException('offline')),
      SyncFailure.offline,
    );
  });
}
