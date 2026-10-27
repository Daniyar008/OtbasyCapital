import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:otbasy_capital/app.dart';
import 'package:otbasy_capital/app/app_store.dart';
import 'package:otbasy_capital/app/startup_app.dart';
import 'package:otbasy_capital/core/services/cloud_storage_service.dart';
import 'package:otbasy_capital/core/services/finance_cloud.dart';
import 'package:otbasy_capital/core/services/storage_service.dart';
import 'package:otbasy_capital/core/services/sync_state.dart';

class ControlledCloud implements FinanceCloud {
  @override
  CloudAccount? account = const CloudAccount(
    id: 'unit-user',
    email: 'test@example.com',
    name: 'Данияр',
  );
  Map<String, dynamic>? remote;
  Object? error;
  Completer<void>? gate;
  @override
  Future<Map<String, dynamic>?> download(String userId) async {
    await gate?.future;
    if (error != null) throw error!;
    return remote == null
        ? null
        : jsonDecode(jsonEncode(remote)) as Map<String, dynamic>;
  }

  @override
  Future<void> upload(String userId, Map<String, dynamic> state) async {
    if (error != null) throw error!;
    remote = jsonDecode(jsonEncode(state)) as Map<String, dynamic>;
  }

  @override
  Future<void> signIn(String email, String password) async {}
  @override
  Future<bool> signUp(String email, String password, String name) async => true;
  @override
  Future<void> signOut() async => account = null;
}

Future<void> capture(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 350));
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final path = Directory('verification/screenshots')
      ..createSync(recursive: true);
    File('${path.path}/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    await (FontLoader('Noto Sans')
          ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/NotoSans-Bold.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets(
    'startup displays loading until account initialization finishes',
    (tester) async {
      final ready = Completer<AppStore>();
      final store = AppStore(storage: MemoryStorageService());
      await tester.pumpWidget(StartupApp(initialize: () => ready.future));
      await tester.pump();
      expect(find.byKey(const ValueKey('startup-loading')), findsOneWidget);
      ready.complete(store);
      await tester.pumpAndSettle();
      expect(find.text('Отбасы бюджеті бір жерде'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );

  testWidgets(
    'startup error can retry and shows loading instead of stale error',
    (tester) async {
      var calls = 0;
      final ready = Completer<AppStore>();
      final store = AppStore(storage: MemoryStorageService());
      await tester.pumpWidget(
        StartupApp(
          initialize: () {
            calls++;
            return calls == 1
                ? Future<AppStore>.error(StateError('unit error'))
                : ready.future;
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('startup-retry')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('startup-retry')));
      await tester.pump();
      expect(find.byKey(const ValueKey('startup-loading')), findsOneWidget);
      expect(find.byKey(const ValueKey('startup-retry')), findsNothing);
      ready.complete(store);
      await tester.pumpAndSettle();
      expect(find.text('Отбасы бюджеті бір жерде'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );

  testWidgets(
    '404 works for guests and signed-in users at three sizes and returns home',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final signedIn in [false, true]) {
        for (final width in [320.0, 390.0, 768.0]) {
          tester.view.physicalSize = Size(width, 844);
          final store = AppStore(storage: MemoryStorageService())
            ..signedIn = signedIn;
          await tester.pumpWidget(
            RepaintBoundary(
              key: const ValueKey('capture'),
              child: OtbasyApp(
                key: UniqueKey(),
                store: store,
                initialLocation: '/missing-page',
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('not-found-code')), findsOneWidget);
          expect(tester.takeException(), isNull);
          if (!signedIn && width == 390) await capture(tester, 'lesson5_404');
          final button = find.text('Басты бетке өту');
          await tester.ensureVisible(button);
          await tester.tap(button);
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('not-found-code')), findsNothing);
          expect(
            find.text(signedIn ? 'Сәлем, Данияр!' : 'Отбасы бюджеті бір жерде'),
            findsOneWidget,
          );
          await tester.pumpWidget(const SizedBox());
          store.dispose();
        }
      }
    },
  );

  testWidgets(
    'loading success timeout offline and GET updates are visible without losing cache',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final memory = MemoryStorageService();
      final seed = AppStore(storage: memory);
      await seed.load();
      seed.dispose();
      final backend = ControlledCloud()
        ..remote = jsonDecode(memory.value!) as Map<String, dynamic>;
      final cloud = CloudStorageService(
        backend: backend,
        storageForAccount: (_) => memory,
      );
      final store = AppStore(storage: cloud, cloud: cloud)..signedIn = true;
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('capture'),
          child: OtbasyApp(store: store, initialLocation: '/home'),
        ),
      );
      await tester.pumpAndSettle();
      var refresh = store.syncCloud();
      await tester.pumpAndSettle();
      await refresh;
      expect(cloud.phase, SyncPhase.success);
      expect(find.text('Бұлтта сақталды'), findsOneWidget);
      await capture(tester, 'lesson5_home');

      (backend.remote!['entries'] as List).first['amount'] = 6000;
      backend.gate = Completer<void>();
      refresh = store.syncCloud();
      await tester.pump(const Duration(milliseconds: 100));
      expect(cloud.phase, SyncPhase.loading);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await capture(tester, 'lesson5_loading');
      backend.gate!.complete();
      await tester.pumpAndSettle();
      await refresh;
      backend.gate = null;
      expect(store.entry('magnum')!.amount, 6000);
      expect(find.text('224 000 ₸'), findsOneWidget);

      backend.error = TimeoutException('unit timeout');
      refresh = store.syncCloud();
      await tester.pumpAndSettle();
      await refresh;
      expect(cloud.failure, SyncFailure.timeout);
      expect(find.textContaining('уақытында жауап бермеді'), findsOneWidget);
      expect(store.entry('magnum')!.amount, 6000);
      await capture(tester, 'lesson5_timeout');

      backend.error = ClientException('unit offline');
      refresh = store.syncCloud();
      await tester.pumpAndSettle();
      await refresh;
      expect(cloud.failure, SyncFailure.offline);
      expect(store.entry('magnum')!.amount, 6000);
      await capture(tester, 'lesson5_offline');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
      cloud.dispose();
    },
  );
}
