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
      final pos = await _fetchAdaptivePosition();
      if (pos == null) {
        await repo.insert(
          LocationPoint(
            latitude: 0,
            longitude: 0,
            timestamp: DateTime.now(),
            error: LocationError.permissionDenied,
          ),
        );
        debugPrint('location unavailable after adaptive attempts');
        return;
      }
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

Future<Position?> _fetchAdaptivePosition() async {
  final attempts = <LocationAccuracy>[
    LocationAccuracy.high,
    LocationAccuracy.medium,
    LocationAccuracy.low,
  ];

  for (final accuracy in attempts) {
    debugPrint('adaptive fetch: trying $accuracy');
    try {
      final LocationSettings settings = Platform.isIOS
          ? AppleSettings(
              accuracy: accuracy,
              activityType: ActivityType.fitness,
              pauseLocationUpdatesAutomatically: false,
              allowBackgroundLocationUpdates: true,
              timeLimit: const Duration(seconds: 10),
            )
          : LocationSettings(
              accuracy: accuracy,
              timeLimit: const Duration(seconds: 10),
            );

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      );
      debugPrint(
        'adaptive fetch: success with $accuracy -> ${pos.latitude}, ${pos.longitude}',
      );
      return pos;
    } catch (e) {
      debugPrint('adaptive fetch: failed with $accuracy -> $e');
    }
  }

  debugPrint('adaptive fetch: trying lastKnownPosition fallback');
  final lastKnown = await Geolocator.getLastKnownPosition();
  if (lastKnown == null) {
    debugPrint('adaptive fetch: lastKnownPosition is null');
  } else {
    debugPrint(
      'adaptive fetch: lastKnownPosition -> ${lastKnown.latitude}, ${lastKnown.longitude}',
    );
  }
  return lastKnown;
}
