# Отбасы капиталы

КМ07 финалдық Flutter жобасы. Қосымша отбасының кірісін, шығысын, жинақ мақсаттарын, төлем еске салғыштарын және ортақ қаржы әрекеттерін бір жерде жүргізуге арналған. Интерфейс қазақ тілінде.

## Іске қосу

VS Code-та C:\Projects\otbasy-capital папкасын ашыңыз:

```powershell
cd C:\Projects\otbasy-capital
flutter pub get
flutter run -d chrome --web-port 5184
```

Flutter 3.47.4 / Dart 3.13.3. RUN_FLUTTER.cmd арқылы да іске қосуға болады.
Тәуелділіктерді жүктеу, тіркелу және алғашқы кіру үшін интернет керек.
Сақталған сессия мен жеке Hive кэші бар кезде жергілікті операциялар интернетсіз орындалады.

Дайын web нұсқасы:

```powershell
flutter build web --release --no-web-resources-cdn
.\START_PREVIEW.cmd
```

Браузерде http://127.0.0.1:5184 ашыңыз. Сервер терезесін ашық қалдырыңыз.
Бір браузер мен бір адресті қолданыңыз: Hive деректері сайт адресіне байланысты сақталады.
Android SDK және құрылғы бапталған болса:

```powershell
flutter devices
flutter run -d <device_id>
```

## Мүмкіндіктер

- Операция қосу, оқу, өзгерту, растаудан кейін жою; қалдықты есептеу.
- Ай және ортақ/жеке көріністі таңдау.
- Атауы, санаты, авторы, ескертпесі бойынша іздеу.
- Санат пен кіріс/шығыс бойынша бірге сүзгілеу.
- Күні, сомасы, атауы бойынша сұрыптау; сүзгілерді тазалау.
- Таңдаулылар, мақсаттар, еске салғыштар және баптауларды сақтау.
- Бос нәтиже мен сақтау қатесін қазақша көрсету.
- Supabase REST API: операциялар үшін GET, POST, PATCH және DELETE.
- Жүктелу, сәттілік, timeout және желі қатесін көрсету; қайта синхрондау.
- Жаңартылған карточкалар, бет анимациясы және жеке 404 беті.
- Камера не галереядан чек суретін тіркеу және оны Supabase Storage-де сақтау.
- Supabase Realtime негізіндегі операциялар синхрондауы және отбасылық чат.
- Gemini көмекші: жеке экранда және чаттағы `@көмекші` командасы арқылы.

Кіру және тіркелу Supabase Auth арқылы орындалады. Өз email-іңізбен тіркеліңіз;
қажет болса, хаттағы сілтемемен адресіңізді растап, қайта кіріңіз.
Жаңа аккаунт бос деректермен басталады. Бұрынғы Demo2026 құпиясөзі нақты аккаунт емес.
Операциялар Supabase-ке жіберіледі, Hive интернетсіз жұмысқа арналған жеке кэш болады.
Қате болса, «Қайта синхрондау» профилдегі түймесін қолданыңыз.
Чек суреті Supabase Storage-дегі жеке `receipts` bucket ішінде сақталады. Gemini сұрауы Flutter-ден тікелей жіберілмейді: ол Supabase Edge Function арқылы орындалады. Құпиясөзді Supabase Auth өңдейді.

Нақты кодтағы сұраулар жолы: [SUPABASE_FLOW.md](docs/SUPABASE_FLOW.md).
DBeaver-де көруге арналған SELECT: [inspect_app.sql](supabase/inspect_app.sql).

## База және код

Hive 2.2.3, hive_flutter 1.1.0 қолданылады.
Бес модель: Family, FamilyMember, MoneyEntry, SavingsGoal, PaymentReminder.
Байланыстар: familyId және ownerId.
FinanceRepository барлық модельдердің күйін Hive box ішіндегі бір Map-жазбаға сақтайды.
Бір put толық күйді бірге жазады; AppStore CRUD пен есептеулерді басқарады.
Оқу жобасына арналған тәсіл. Үлкен дерек көлеміне бөлек жазбалар мен индекстер қажет.

FinanceRepository.local() алдыңғы shared_preferences деректерін бір рет көшіруді қолдайды.
Бұлттық режим бұл көшірмені жаңа аккаунттарға импорттамайды: әр аккаунтқа бөлек Hive box беріледі.
Бүлінген база автоматты ауыстырылмайды: қате көрсетіліп, жазу бұғатталады.
Қалпына келтіру баптауларда растаудан кейін орындалады.

- lib/core/services/ - база және сақтау интерфейсі
- lib/features/ - модельдер мен экрандар
- lib/app/ - күй, есептеу, маршруттар
- lib/shared/widgets/ - ортақ элементтер
- test/ - автоматты тексерулер
- docs/LESSON4.md - модельдер және тапсырманың 20 тармағы
- docs/VERIFICATION.md - тексеру нәтижелері
- docs/LESSON5.md - API endpoint-тері және бесінші жұмыстың 20 тармағы
- docs/ARCHITECTURE.md - жобаның архитектурасы және Mermaid диаграммасы
- docs/FINAL_TEST_CASES.md - №8 жұмысқа арналған 18 Test Case
- docs/BUG_REPORT.md - анықталған қателер мен түзетулер
- docs/USER_GUIDE.md - қолданушы нұсқаулығы
- docs/DEMO_SCRIPT.md - 2-3 минуттық видео сценарийі
- docs/APK_BUILD_STATUS.md - Android NDK мен APK build күйі

## Тексеру

```powershell
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
flutter build apk --release
```

lesson4_storage_test.dart нақты уақытша Hive файлын ашады, CRUD орындайды, базаны жауып қайта ашады.
Операциялар мен таңдаулылар салыстырылады. Осы сценарийде HTTP клиентін құруға тыйым салынған.

Құжаттама: https://pub.dev/packages/hive және https://pub.dev/packages/hive_flutter

## APK жинағы

```powershell
flutter build apk --release
```

Сәтті жинақтан кейін APK мына жерде шығады:

```text
build\\app\\outputs\\flutter-apk\\app-release.apk
```

## Қорғауға арналған материалдар

- Архитектура: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Тесттер: [docs/FINAL_TEST_CASES.md](docs/FINAL_TEST_CASES.md)
- Қателер: [docs/BUG_REPORT.md](docs/BUG_REPORT.md)
- Нұсқаулық: [docs/USER_GUIDE.md](docs/USER_GUIDE.md)
- Demo: [docs/DEMO_SCRIPT.md](docs/DEMO_SCRIPT.md)
- APK build: [docs/APK_BUILD_STATUS.md](docs/APK_BUILD_STATUS.md)
