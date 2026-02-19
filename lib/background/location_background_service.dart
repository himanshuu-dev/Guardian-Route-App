import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

import '../data/location_repository.dart';
import '../models/location_point.dart';

Timer? _trackingTimer;

@pragma('vm:entry-point')
void locationService(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  service.on('stopService').listen((_) async {
    _trackingTimer?.cancel();
    _trackingTimer = null;
    service.stopSelf();
  });

  final repo = LocationRepository(enablePolling: false);

  _trackingTimer?.cancel();
  _trackingTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
    debugPrint('locationService called');

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        await repo.insert(
          LocationPoint(
            latitude: 0,
            longitude: 0,
            timestamp: DateTime.now(),
            error: LocationError.gpsDisabled,
          ),
        );
        return;
      }

      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always) {
        await repo.insert(
          LocationPoint(
            latitude: 0,
            longitude: 0,
            timestamp: DateTime.now(),
            error: LocationError.permissionDenied,
          ),
        );
        debugPrint('permission denied in background');
        return;
      }

      debugPrint('fetching location');
      final LocationSettings locationSettings = Platform.isIOS
          ? AppleSettings(
              activityType: ActivityType.fitness,
              pauseLocationUpdatesAutomatically: false,
              allowBackgroundLocationUpdates: true,
            )
          : AndroidSettings();
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      debugPrint('location inserted ${pos.latitude}, ${pos.longitude}');

      await repo.insert(
        LocationPoint(
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracy: pos.accuracy,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e, st) {
      debugPrint('location fetch failed: $e');
      debugPrintStack(stackTrace: st);
      await repo.insert(
        LocationPoint(
          latitude: 0,
          longitude: 0,
          timestamp: DateTime.now(),
          error: LocationError.permissionDenied,
        ),
      );
    }
  });
}
