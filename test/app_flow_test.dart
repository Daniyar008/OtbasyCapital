import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otbasy_capital/app.dart';
import 'package:otbasy_capital/features/transactions/widgets/entry_card.dart';
import 'package:otbasy_capital/app/app_store.dart';
import 'package:otbasy_capital/core/services/storage_service.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<AppStore> mountApp(
  WidgetTester tester, {
  String route = '/',
  bool authenticated = false,
  Size size = const Size(390, 844),
  bool large = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  final store = AppStore(storage: MemoryStorageService())
    ..signedIn = authenticated
    ..largeText = large;
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('capture'),
      child: OtbasyApp(key: UniqueKey(), store: store, initialLocation: route),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

Future<void> capture(WidgetTester tester, String name) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('verification/screenshots')
      ..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Noto Sans')
      ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    await loader.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  testWidgets('complete defense flow edits a real entry and reaches Profile', (
    tester,
  ) async {
    final store = await mountApp(tester);
    await capture(tester, '01_splash');
    await tapText(tester, 'Бастау');
    await capture(tester, '02_login');
    await tapText(tester, 'Кіру');
    expect(find.text('225 000 ₸'), findsOneWidget);
    await capture(tester, '03_home');
    await tester.tap(find.byKey(const ValueKey('nav-1')));
    await tester.pumpAndSettle();
    await tapText(tester, 'Magnum');
    await tapText(tester, 'Өзгерту');
    await tester.enterText(find.byKey(const ValueKey('entry-amount')), '4000');
    await capture(tester, '04_edit');
    await tapText(tester, 'Өзгерісті сақтау');
    expect(store.balance, 226000);
    expect(find.text('226 000 ₸'), findsOneWidget);
    await capture(tester, '05_result');
    await tapText(tester, 'Профильге өту');
    expect(find.text('Менің отбасым'), findsOneWidget);
    await capture(tester, '06_profile');
    expect(tester.takeException(), isNull);
  });
  testWidgets('invalid email and empty password show readable errors', (
    tester,
  ) async {
    await mountApp(tester, route: '/login');
    await tester.enterText(find.byKey(const ValueKey('email')), 'broken');
    await tester.enterText(find.byKey(const ValueKey('password')), '');
    await tapText(tester, 'Кіру');
    expect(
      find.text('Email дұрыс емес. Мысалы: daniyar@example.com'),
      findsOneWidget,
    );
    expect(find.text('Құпиясөзді енгізіңіз.'), findsOneWidget);
    await capture(tester, '07_validation');
  });
  testWidgets('empty create form is blocked then saves actual input', (
    tester,
  ) async {
    final store = await mountApp(
      tester,
      route: '/entry/new',
      authenticated: true,
    );
    await tapText(tester, 'Сақтау');
    expect(find.text('Соманы енгізіңіз.'), findsOneWidget);
    expect(find.text('Бұл өрісті толтырыңыз.'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('entry-amount')), '2000');
    await tester.enterText(
      find.byKey(const ValueKey('entry-title')),
      'Жаңа сатып алу',
    );
    await tapText(tester, 'Сақтау');
    expect(
      store.accessibleEntries.any(
        (e) => e.title == 'Жаңа сатып алу' && e.amount == 2000,
      ),
      isTrue,
    );
    expect(find.text('Операция сақталды'), findsOneWidget);
  });
  testWidgets('favorites toggle, search and confirmed deletion work', (
    tester,
  ) async {
    final store = await mountApp(
      tester,
      route: '/entry/magnum',
      authenticated: true,
    );
    await tapText(tester, 'Таңдаулыларға қосу');
    expect(store.entry('magnum')!.favorite, isTrue);
    await tester.tap(find.byKey(const ValueKey('nav-3')));
    await tester.pumpAndSettle();
    await tapText(tester, 'Таңдаулылар');
    await tapText(tester, 'Magnum');
    await tapText(tester, 'Операцияны жою');
    await tapText(tester, 'Бас тарту');
    expect(store.entry('magnum'), isNotNull);
    await tapText(tester, 'Операцияны жою');
    await tapText(tester, 'Иә, жою');
    expect(store.entry('magnum'), isNull);
    expect(store.balance, 230000);
    await tapText(tester, 'Тарихқа өту');
    await tapText(tester, 'Операцияны іздеу');
    await tester.enterText(
      find.byKey(const ValueKey('search-query')),
      'NoResult123',
    );
    await tester.pumpAndSettle();
    expect(find.text('Ештеңе табылмады'), findsOneWidget);
    await tapText(tester, 'Сүзгілерді тазалау');
    expect(find.text('Жалақы'), findsOneWidget);
  });
  testWidgets('registration blocks mismatch and connects family setup', (
    tester,
  ) async {
    await mountApp(tester, route: '/register');
    await tester.enterText(
      find.byKey(const ValueKey('register-name')),
      'Аружан',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-email')),
      'aruzhan@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-password')),
      'Demo2026',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-repeat')),
      'different',
    );
    await tapText(tester, 'Тіркелу');
    expect(find.text('Құпиясөздер сәйкес келмейді.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('register-repeat')),
      'Demo2026',
    );
    await tapText(tester, 'Тіркелу');
    expect(find.text('Отбасымен бастау'), findsOneWidget);
  });
  testWidgets('create a goal and contribute updates its details', (
    tester,
  ) async {
    final store = await mountApp(tester, route: '/goals', authenticated: true);
    await tapText(tester, '+ Мақсат қосу');
    await tester.enterText(find.byKey(const ValueKey('goal-title')), 'Оқу');
    await tester.enterText(find.byKey(const ValueKey('goal-amount')), '100000');
    await tapText(tester, 'Мақсатты сақтау');
    expect(store.goals.any((goal) => goal.title == 'Оқу'), isTrue);
    await tapText(tester, 'Үлес қосу');
    await tester.enterText(
      find.byKey(const ValueKey('contribution-amount')),
      '10000',
    );
    await tapText(tester, 'Үлесті сақтау');
    expect(find.text('Мақсаттың 10%-ы орындалды.'), findsOneWidget);
    await tapText(tester, 'Мақсатқа оралу');
    expect(find.text('10 000 ₸'), findsWidgets);
    expect(store.balance, 225000);
  });
  testWidgets('reminders and accessible text settings save through the UI', (
    tester,
  ) async {
    final store = await mountApp(
      tester,
      route: '/reminders',
      authenticated: true,
    );
    await tapText(tester, '+ Еске салғыш қосу');
    await tester.enterText(
      find.byKey(const ValueKey('reminder-title')),
      'Оқу төлемі',
    );
    await tapText(tester, 'Сақтау');
    expect(store.reminders.last.title, 'Оқу төлемі');
    await tapText(tester, 'Еске салғыштарға оралу');
    final done = find.byTooltip('Орындалды деп белгілеу').last;
    await tester.ensureVisible(done);
    await tester.tap(done);
    await tester.pumpAndSettle();
    expect(store.reminders.last.done, isTrue);
    await tapText(tester, 'Хабарландыру баптаулары');
    await tester.tap(find.byKey(const ValueKey('large-text')));
    await tester.pumpAndSettle();
    await tapText(tester, 'Өзгерістерді сақтау');
    expect(store.largeText, isTrue);
    expect(find.text('Баптаулар сақталды'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  const routes = [
    '/',
    '/onboarding/1',
    '/onboarding/2',
    '/login',
    '/register',
    '/reset-password',
    '/family-setup',
    '/home',
    '/history',
    '/entry/magnum',
    '/entry/new',
    '/entry/magnum/edit',
    '/search',
    '/favorites',
    '/budget',
    '/reports',
    '/goals',
    '/goal/holiday',
    '/goal/new',
    '/goal/holiday/contribute',
    '/family',
    '/reminders',
    '/reminder/new',
    '/profile',
    '/settings',
    '/assistant',
    '/result',
  ];
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(768, 1024),
  ]) {
    testWidgets('all routes open without overflow at ${size.width.toInt()}px', (
      tester,
    ) async {
      for (final route in routes) {
        await mountApp(
          tester,
          route: route,
          authenticated: true,
          size: size,
          large: size.width != 390,
        );
        expect(tester.takeException(), isNull, reason: 'Route $route at $size');
        if (size.width == 390) {
          final index = routes.indexOf(route).toString().padLeft(2, '0');
          final slug = route == '/'
              ? 'splash'
              : route.substring(1).replaceAll('/', '_');
          await capture(tester, 'screen_${index}_$slug');
        }
      }
      await mountApp(
        tester,
        route: '/home',
        authenticated: true,
        size: size,
        large: true,
      );
      await capture(tester, '08_responsive_${size.width.toInt()}');
    });
  }
  testWidgets('lesson 4 filters, sorting and reset change visible results', (
    tester,
  ) async {
    await mountApp(tester, route: '/search', authenticated: true);
    await tapText(tester, 'Сүзгі және сұрыптау');
    await tapText(tester, 'Күні: жаңадан ескіге');
    await tapText(tester, 'Сома: көптен азға');
    expect(
      tester.widgetList<EntryCard>(find.byType(EntryCard)).first.entry.id,
      'salary',
    );
    final category = find
        .widgetWithText(DropdownButtonFormField<String>, 'Барлығы')
        .last;
    await tester.ensureVisible(category);
    await tester.tap(category);
    await tester.pumpAndSettle();
    await tapText(tester, 'Азық-түлік');
    expect(
      tester
          .widgetList<EntryCard>(find.byType(EntryCard))
          .map((w) => w.entry.amount),
      [45000, 5000],
    );
    await capture(tester, 'lesson4_filters');
    await tapText(tester, 'Сүзгілерді тазалау');
    expect(find.byType(EntryCard), findsNWidgets(7));
    expect(tester.takeException(), isNull);
  });
}
