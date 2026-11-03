import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum NotificationPermissionState { granted, denied, unavailable }

class NotificationPermissionService {
  const NotificationPermissionService();

  /// Requests the operating-system permission only on a supported device.
  Future<NotificationPermissionState> request() async {
    if (kIsWeb) return NotificationPermissionState.unavailable;
    try {
      final status = await Permission.notification.request();
      return _fromStatus(status);
    } catch (_) {
      return NotificationPermissionState.unavailable;
    }
  }

  Future<NotificationPermissionState> current() async {
    if (kIsWeb) return NotificationPermissionState.unavailable;
    try {
      return _fromStatus(await Permission.notification.status);
    } catch (_) {
      return NotificationPermissionState.unavailable;
    }
  }

  NotificationPermissionState _fromStatus(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return NotificationPermissionState.granted;
    }
    return NotificationPermissionState.denied;
  }
}
