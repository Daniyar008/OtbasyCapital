import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/reminders/models/payment_reminder.dart';
import 'notification_permission_service.dart';

/// Plans payment reminders on Android after the user grants notification access.
class ReminderNotificationService {
  ReminderNotificationService._();
  static final instance = ReminderNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> initialize() async {
    if (kIsWeb || _ready) return;
    tz.initializeTimeZones();
    try {
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _ready = true;
    } catch (_) {
      // A browser and widget tests do not have the Android notification plugin.
    }
  }

  Future<bool> schedule(PaymentReminder reminder) async {
    if (kIsWeb || reminder.done || !_ready) return false;
    if (await const NotificationPermissionService().current() !=
        NotificationPermissionState.granted) {
      return false;
    }
    final now = tz.TZDateTime.now(tz.local);
    var date = tz.TZDateTime(
      tz.local,
      reminder.date.year,
      reminder.date.month,
      reminder.date.day,
      9,
    );
    if (date.isBefore(now)) date = now.add(const Duration(minutes: 1));
    await _plugin.zonedSchedule(
      _id(reminder.id),
      'Отбасы капиталы',
      '${reminder.title} төлемін ұмытпаңыз.',
      date,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'payment_reminders',
          'Төлем еске салғыштары',
          channelDescription: 'Отбасы капиталы төлем еске салғыштары',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: reminder.monthly
          ? DateTimeComponents.dayOfMonthAndTime
          : null,
    );
    return true;
  }

  Future<void> cancel(String reminderId) async {
    if (kIsWeb || !_ready) return;
    await _plugin.cancel(_id(reminderId));
  }

  int _id(String value) =>
      value.codeUnits.fold(0, (sum, code) => (sum * 31 + code) & 0x7fffffff);
}
