import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

import '../data/location_repository.dart';
import '../models/location_point.dart';

@pragma('vm:entry-point')
void locationService(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final repo = LocationRepository();

  Timer.periodic(const Duration(minutes: 5), (_) async {
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

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      await repo.insert(
        LocationPoint(
          latitude: pos.latitude,
          longitude: pos.longitude,
          timestamp: DateTime.now(),
        ),
      );
    } catch (_) {
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
