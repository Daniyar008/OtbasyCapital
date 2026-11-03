# Google кіруі және Realtime баптауы

Бұл жоба Google арқылы кіруге, операцияны Realtime арқылы жаңартуға және чек суретін сақтауға дайын. Алдымен Supabase SQL Editor ішінде `supabase/migrations/20261103_002_realtime_receipts.sql` файлын толық орындау керек.

Google кіруі үшін Supabase Dashboard -> Authentication -> Providers -> Google бөліміне өтіп, Google provider-ді қосу қажет. Google Cloud Console-де OAuth Client ID жасағанда `https://cjssoiwliiaeenyicdxu.supabase.co/auth/v1/callback` адресін Authorized redirect URI ретінде енгізу керек. Supabase Dashboard -> Authentication -> URL Configuration ішіне `http://127.0.0.1:8080`, кейін Render адресі және Android үшін `kz.otbasy.otbasycapital://login-callback` redirect URL-ін қосыңыз.

SQL орындалғаннан кейін Realtime кестесі мен `receipts` bucket дайын болады. Фото 5 МБ-тан аспауы және JPG, PNG немесе WEBP форматында болуы тиіс. Bucket жеке: әр қолданушы тек өз папкасындағы файлды көре алады.

Отбасылық чат үшін SQL Editor-де `supabase/migrations/20261103_003_family_chat.sql` файлын да орындау керек. Бұл файл `otbasy_family_messages` кестесін құрып, оны `supabase_realtime` publication-ына қосады. Чат экранында хабарлар WebSocket арқылы автоматты жаңарады.

Нағыз AI жауабы үшін Supabase Edge Functions -> Secrets ішінде `GEMINI_API_KEY` secret-ін сақтау керек. Содан кейін Edge Functions -> Deploy a new function -> Via Editor таңдап, атауын `ai-chat` деп жазыңыз да, `supabase/functions/ai-chat/index.ts` файлының кодын енгізіп Deploy басыңыз. Функция `gemini-2.5-flash-lite` моделін шақырады. API key Flutter коды мен GitHub-қа жазылмайды.
