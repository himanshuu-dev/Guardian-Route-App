import 'package:flutter_background_service/flutter_background_service.dart';
import '../background/location_background_service.dart';

class LocationService {
  static Future<void> start() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: locationService,
        isForegroundMode: true,
        notificationChannelId: 'guardian_route',
        initialNotificationTitle: 'Guardian Route',
        initialNotificationContent: 'Tracking location',
      ),
      iosConfiguration: IosConfiguration(onForeground: locationService),
    );

    await service.startService();
  }

  static void stop() {
    FlutterBackgroundService().invoke('stopService');
  }
}
