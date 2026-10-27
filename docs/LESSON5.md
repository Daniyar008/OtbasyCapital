# Практикалық жұмыс №5

Жоба: «Отбасы капиталы». Бұл жұмыста Supabase REST API арқылы операцияларды
алу, қосу, өзгерту және жою іске асырылды. Интерфейстегі деректер Hive кэшімен
байланыстырылды. Сұраудың орындалуы мен қатесі экранда көрсетіледі.

## Қолданылған API

Негізгі адрес: `https://cjssoiwliiaeenyicdxu.supabase.co`.
Supabase Auth аккаунт пен сессияны басқарады, PostgREST PostgreSQL кестелеріне
сұрау жібереді. SDK-ның `select`, `insert`, `update`, `delete` әдістері сәйкес
HTTP сұрауларын орындайды. Бұл ORM емес: Dart модельдері мен API қызметі бөлек жазылған.

| Endpoint | HTTP әдісі | Әрекет және код |
|---|---|---|
| /auth/v1/signup | POST | signUp: аккаунт тіркеу |
| /auth/v1/token?grant_type=password | POST | signIn: аккаунтқа кіру |
| /rest/v1/otbasy_entries | GET | getEntries: операцияларды оқу |
| /rest/v1/otbasy_entries?select=id | GET | _writeEntries: өзгертілетін ID бар-жоғын тексеру |
| /rest/v1/otbasy_entries | POST | createEntry: жаңа операция |
| /rest/v1/otbasy_entries?id=eq.ID | PATCH | updateEntry: сома, атау, санат және басқа өрістер |
| /rest/v1/otbasy_entries?id=in.(ID) | DELETE | deleteEntries: таңдалған операцияларды жою |
| /rest/v1/otbasy_families | GET, POST | Отбасы атауын оқу және сақтау |
| /rest/v1/otbasy_members | POST | Қатысушыларды сақтау |
| /rest/v1/otbasy_goals | GET, POST, DELETE | Мақсаттар мен үлестер |
| /rest/v1/otbasy_reminders | GET, POST, DELETE | Еске салғыштар |

Кестелерге GET, PATCH және DELETE жібергенде user_id және family_id сүзгілері
қолданылады. RLS серверде auth.uid() мәнін тексереді. Аккаунтсыз оқу рұқсат етілмейді.
JSON денесі мен JWT-ны Supabase SDK жібереді. PostgreSQL паролі Flutter кодына жазылмайды.
Көмекші кестелерде бұрынғы upsert сақталған; операциялар үшін POST және PATCH бөлек орындалады.

## Орындалған тапсырмалар

| № | Талап | Жобадағы орындалуы |
|---|---|---|
| 1 | REST API таңдау | Supabase Auth және Data API |
| 2 | Endpoint тізімі | Жоғарыдағы кесте |
| 3 | HTTP әдісі мен әрекет | GET, POST, PATCH, DELETE және әдістердің атаулары |
| 4 | HTTP кітапханасы | supabase_flutter және http, pubspec.yaml |
| 5 | GET | SupabaseFinanceService.getEntries және download |
| 6 | JSON → Dart Model | download карталары → AppStore.load → MoneyEntry.fromJson, SavingsGoal.fromJson, PaymentReminder.fromJson |
| 7 | Сервер деректерін көрсету | HomeScreen, HistoryScreen және EntryCard |
| 8 | POST | createEntry → client.from(...).insert(row) |
| 9 | PUT немесе PATCH | updateEntry → update(values), ID және аккаунт сүзгісі |
| 10 | DELETE | deleteEntries → delete(), тек нақты ID тізімі |
| 11 | async/await | API қызметі, сақтау қабаты және экран формалары |
| 12 | Loading | StartupApp, CloudSyncBanner және бос емес түйме индикаторы |
| 13 | Success | SyncPhase.success, «Бұлтта сақталды», жаңартылған тізім мен қалдық |
| 14 | Server Error | PostgrestException → SyncFailure.server, қате күйі және қайта сұрау |
| 15 | Интернет жоқ | ClientException, жеке Hive кэші мен жіберілмеген өзгерістер кезегі |
| 16 | Timeout | main.dart: requestTimeout 10 секунд; TimeoutException үшін жеке хабарлама |
| 17 | Exception | Auth, HTTP, JSON және басқа қателерді өңдеу |
| 18 | Сервер және жергілікті дерек | CloudStorageService: алдымен Hive, кейін API; қайта ашқанда кезекті жіберу |
| 19 | Әр HTTP әдісін бөлек тексеру | lesson5_http_test.dart: GET, POST, PATCH, DELETE жеке тесттері |
| 20 | Интерфейстің жаңаруы | lesson5_ui_test.dart: сервер сомасы өзгергенде MoneyEntry мен қалдық жаңарады |

## Сұраудың орындалуы

Операция формасындағы сақтау түймесі `EntryFormScreen._save()` әдісін шақырады.
Ол `AppStore.saveEntry()` арқылы тізімді өзгертеді. `CloudStorageService.write()`
Hive-қа күйді және жіберілетін ID-лерді сақтайды. API қызметі ID-ді серверден
тексеріп, `createEntry()` немесе `updateEntry()` шақырады. Жою үшін жеке ID кезегі бар.

Қате болса, кезек тазаланбайды. Келесі сақтау, аккаунтты қайта ашу немесе
«Қайта синхрондау» әрекеті оны қайталайды. Сәтті аяқталғанда кезек тазаланып,
индикатор жасыл күйге өтеді. Желінің қалпына келуін бақылайтын фондық таймер жоқ.
Бір жазбаны екі құрылғыда бір уақытта өңдегенде соңғы сәтті өзгеріс сақталады.

## Дизайн

Жасыл түстер сақталып, ақ карточкалар мен дөңгелек бұрыштар біріздендірілді.
Қалдық карточкасында жұмсақ градиент, кіріс пен шығысқа бөлек блоктар бар.
Операция сомасы оң жақта, түсі бойынша ажыратылады. Төменгі навигацияда белсенді
бөлім белгіленеді. Беттердің пайда болуы, қалдық пен навигация ауысуы анимацияланған.

Белгісіз сілтемеге жеке 404 беті қосылды. Одан басты бетке немесе кіруге оралуға болады.
Сервер index.html файлын қайтаратын rewrite қолданады; маршрутты Flutter анықтайды.
Бұл SPA ішіндегі 404 беті, HTTP жауабының мәртебесі хостинг rewrite-іне байланысты 200 болуы мүмкін.
Жарамды жеке бетке аккаунтсыз кіруге бұрынғыдай рұқсат жоқ.

## Тексеру туралы

Release web жинағы құрылды. 39 автоматты тест өтті; статикалық талдауда мәселе табылған жоқ.
Журналдар verification/ ішінде, жаңартылған 404 көрінісі кейін жеке UI тестімен қайта тексерілді.

HTTP тесттері нақты Supabase SDK мен басқарылатын HTTP жауаптарын қолданады.
UI тесттері жүктелу, сәттілік, timeout, интернет қатесі және кэштің сақталуын тексереді.
404 беті 320, 390 және 768 пиксель өлшемдерінде, аккаунтпен және аккаунтсыз тексеріледі.
Бұл тесттер нақты сервердегі пайдаланушы деректерін өзгертпейді.
Нақты аккаунтпен соңғы тексеру үшін email-ді растап, қосымшаға кіру қажет.
Нақты Android құрылғысындағы тексеру мен APK жинағы бұл жерде дайын деп көрсетілмейді.

Экран көріністері (widget тестінің оқу деректері):
- [Негізгі экран](screenshots/lesson5-home.png)
- [404 беті](screenshots/lesson5-404.png)

## Қорытынды

Қосымша REST API арқылы деректерді алады және өзгертеді. Әр HTTP әдісі кодта
жеке көрсетілген. Сұрау қатесі кезінде жергілікті деректер жоғалмайды және
пайдаланушы қайта сұрау жібере алады. Дизайн жаңартылып, 404 беті қосылды.

SDK құжаттамасы:
- https://supabase.com/docs/reference/dart/select
- https://supabase.com/docs/reference/dart/insert
- https://supabase.com/docs/reference/dart/update
- https://supabase.com/docs/reference/dart/delete
