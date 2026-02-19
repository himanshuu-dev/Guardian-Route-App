import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../background/location_background_service.dart';

class LocationService {
  static Future<void> initialize() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'guardian_route',
        channelName: 'Guardian Route Tracking',
        channelDescription: 'Location tracking service',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
        eventAction: ForegroundTaskEventAction.repeat(300000),
      ),
    );

    if (await FlutterForegroundTask.checkNotificationPermission() !=
        NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  static Future<bool> start() async {
    if (await FlutterForegroundTask.isRunningService) {
      return true;
    }

    final result = await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Guardian Route',
      notificationText: 'Tracking location in background',
      notificationIcon: null,
      notificationButtons: null,
      callback: startLocationTaskCallback,
    );

    return result is ServiceRequestSuccess;
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }

  static Future<bool> isRunning() async {
    return FlutterForegroundTask.isRunningService;
  }
}
