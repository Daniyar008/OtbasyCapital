# APK build күйі

6 қараша 2026 жылы `flutter build apk --release` командасы іске қосылды.

## Нәтиже

Flutter кодының compile кезеңіне дейін Gradle Android NDK қатесін берді:

```text
[CXX1101] NDK at C:\Users\Admin\AppData\Local\Android\sdk\ndk\28.2.13676358
did not have a source.properties file
```

Бұл жоба кодындағы қате емес. Компьютердегі `28.2.13676358` NDK қалтасы бос не толық жүктелмеген.

## Түзету

1. Android Studio ашыңыз.
2. `More Actions` - `SDK Manager` - `SDK Tools` бөліміне өтіңіз.
3. `NDK (Side by side)` таңдаңыз.
4. `28.2.13676358` нұсқасын қайта орнатыңыз.
5. Терминалда келесі команданы қайта орындаңыз:

```powershell
cd C:\Projects\otbasy-capital
flutter build apk --release
```

Дайын файл:

```text
build\app\outputs\flutter-apk\app-release.apk
```
