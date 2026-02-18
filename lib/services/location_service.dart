import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../background/location_background_service.dart';

class LocationService {
  static Future<void> start() async {
    final service = FlutterBackgroundService();

    // 🔴 CREATE CHANNEL FIRST
    const channel = AndroidNotificationChannel(
      'guardian_route',
      'Guardian Route Tracking',
      description: 'Location tracking service',
      importance: Importance.low,
    );

    final notifications = FlutterLocalNotificationsPlugin();
    await notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: locationService,
        isForegroundMode: true,
        notificationChannelId: 'guardian_route',
        initialNotificationTitle: 'Guardian Route',
        initialNotificationContent: 'Tracking location in background',
      ),
      iosConfiguration: IosConfiguration(onForeground: locationService),
    );

    await service.startService();
  }

  static void stop() {
    FlutterBackgroundService().invoke('stopService');
  }
}
