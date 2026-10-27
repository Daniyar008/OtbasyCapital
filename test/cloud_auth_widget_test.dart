import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otbasy_capital/app.dart';
import 'package:otbasy_capital/app/app_store.dart';
import 'package:otbasy_capital/core/services/cloud_storage_service.dart';
import 'package:otbasy_capital/core/services/finance_cloud.dart';
import 'package:otbasy_capital/core/services/storage_service.dart';

class UiCloud implements FinanceCloud {
  @override
  CloudAccount? account;
  int signupCalls = 0;
  @override
  Future<void> signIn(String email, String password) async {
    if (password != 'Valid2026') {
      throw const AuthException(
        'Invalid credentials',
        code: 'invalid_credentials',
      );
    }
    account = CloudAccount(id: 'user-a', email: email, name: 'Данияр');
  }

  @override
  Future<bool> signUp(String email, String password, String name) async {
    signupCalls++;
    return false;
  }

  @override
  Future<void> signOut() async => account = null;
  @override
  Future<Map<String, dynamic>?> download(String userId) async => null;
  @override
  Future<void> upload(String userId, Map<String, dynamic> state) async {}
}

void main() {
  late UiCloud backend;
  late CloudStorageService cloud;
  late AppStore store;
  setUp(() {
    backend = UiCloud();
    final cache = MemoryStorageService();
    cloud = CloudStorageService(
      backend: backend,
      storageForAccount: (_) => cache,
    );
  });
  tearDown(() {
    store.dispose();
    cloud.dispose();
  });
  Future<void> mount(WidgetTester tester, String route) async {
    store = AppStore(storage: cloud, cloud: cloud);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(OtbasyApp(store: store, initialLocation: route));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    final button = find.text(text).last;
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'cloud login starts with empty credentials and rejects wrong password',
    (tester) async {
      await mount(tester, '/login');
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('email')))
            .controller!
            .text,
        '',
      );
      await tester.enterText(
        find.byKey(const ValueKey('email')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('password')),
        'Wrong2026',
      );
      await tap(tester, 'Кіру');
      expect(store.signedIn, isFalse);
      expect(
        find.text('Email немесе құпиясөз қате.'),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .join(' | '),
      );
      await tester.enterText(
        find.byKey(const ValueKey('password')),
        'Valid2026',
      );
      await tap(tester, 'Кіру');
      expect(store.signedIn, isTrue);
      expect(store.accessibleEntries, isEmpty);
      expect(find.text('Жалпы қалдық'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'signup without a session asks to confirm email and never opens family data',
    (tester) async {
      await mount(tester, '/register');
      await tester.enterText(
        find.byKey(const ValueKey('register-name')),
        'Данияр',
      );
      await tester.enterText(
        find.byKey(const ValueKey('register-email')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('register-password')),
        'Valid2026',
      );
      await tester.enterText(
        find.byKey(const ValueKey('register-repeat')),
        'Valid2026',
      );
      await tap(tester, 'Тіркелу');
      expect(
        backend.signupCalls,
        1,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .join(' | '),
      );
      expect(store.signedIn, isFalse);
      expect(find.text('Email мекенжайын растаңыз'), findsOneWidget);
      expect(find.text('Кіруге өту'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
