# Render-де жариялау

Жоба Flutter Web ретінде Render Static Site-қа жарияланады.
Баптаулар `render.yaml` ішінде, жинау командасы `tools/render_build.sh` ішінде.
Flutter ресми GitHub репозиторийінен stable арнасы орнатылады.
Жинақтың басында Flutter және Dart нұсқалары журналға жазылады.
Қажет болса, Render-дегі FLUTTER_REF build айнымалысы арқылы үйлесімді
ресми Flutter тегін бекітуге болады. Жобаның Dart талабы: ^3.13.0.

1. https://dashboard.render.com/ сайтына кіріңіз.
2. **New → Blueprint** таңдап, GitHub-тегі `Daniyar008/OtbasyCapital` репозиторийін қосыңыз.
3. `main` тармағын және репозиторий түбіріндегі `render.yaml` файлын қолданыңыз.
4. Render ұсынған қызметтер мен төлем шарттарын қарап, Blueprint-ті іске қосыңыз.
5. Жинақ сәтті аяқталған соң Render көрсеткен `https://….onrender.com` адресін ашыңыз.

Blueprint орнына қолмен **New → Static Site** ашылса:

- Repository: Daniyar008/OtbasyCapital
- Branch: main
- Root Directory: бос
- Build Command: bash tools/render_build.sh
- Publish Directory: build/web
- Rewrite: /* → /index.html

Қолмен жасалған Static Site үшін rewrite ережесін Render Dashboard ішінде
**Redirects/Rewrites → Add Rule** арқылы қосыңыз: Source `/*`, Destination
`/index.html`, Action `Rewrite`. Blueprint-тегі render.yaml бұл ережені өзі береді;
қолмен ашылған қызметке YAML баптауы автоматты қолданылмайды. Бұл ереже /404,
/history сияқты тікелей адрестерді жаңартқанда Flutter бетін ашу үшін қажет.

Жинақ тексерілмейінше сайт жарияланды деп есептелмейді. Нақты Render адресі
қызмет құрылғаннан кейін ғана белгілі болады. Авторизацияны пайдаланушы өзі өтеді.

Hive деректері әр браузерде және әр сайт адресінде бөлек сақталады.
localhost-тағы деректер Render адресіне автоматты көшпейді.
Қазіргі main.dart Supabase Auth және CloudStorageService қолданады.
Тіркелген аккаунт деректері Supabase-тен жүктеліп, жеке Hive кэшіне жазылады.
Жаңа нұсқаны Render-де көрсету үшін осы commit бойынша қайта жинау қажет.
PostgreSQL паролі мен service_role кілті static сайтқа енгізілмейді.

Static Site серверді ашық ұстап отыру үшін жергілікті компьютерді қажет етпейді.
Хостингтің нақты қолжетімділігі мен лимиттері Render шарттарына байланысты.
