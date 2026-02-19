import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '../data/location_repository.dart';
import '../models/location_point.dart';

@pragma('vm:entry-point')
void startLocationTaskCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  final LocationRepository _repo = LocationRepository(enablePolling: false);

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('Location capture service started');
    await _captureAndStoreLocation();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    debugPrint('Location capture service repeated');
    unawaited(_captureAndStoreLocation());
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    debugPrint('Location capture service destroyed');

    _repo.dispose();
  }

  Future<void> _captureAndStoreLocation() async {
    debugPrint('Location capture service called');

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        await _insertError(LocationError.gpsDisabled);
        return;
      }

      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always) {
        await _insertError(LocationError.permissionDenied);
        return;
      }

      final pos = await getSmartLocation();
      if (pos != null) {
        debugPrint('Location capture ${pos.latitude},${pos.longitude}');

        final now = DateTime.now();
        await _repo.insert(
          LocationPoint(
            latitude: pos.latitude,
            longitude: pos.longitude,
            accuracy: pos.accuracy,
            timestamp: now,
          ),
        );
        debugPrint('Location inserted');

        FlutterForegroundTask.updateService(
          notificationText:
              'Last update: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        );
        FlutterForegroundTask.sendDataToMain({
          'type': 'location_saved',
          'timestamp': now.millisecondsSinceEpoch,
        });
      } else {
        await _insertError(LocationError.unknown);
      }
    } catch (e, st) {
      debugPrint('background location capture failed: $e');
      debugPrintStack(stackTrace: st);
      await _insertError(LocationError.permissionDenied);
    }
  }

  Future<void> _insertError(LocationError error) async {
    final now = DateTime.now();
    await _repo.insert(
      LocationPoint(latitude: 0, longitude: 0, timestamp: now, error: error),
    );
    debugPrint('Location insert with error');

    FlutterForegroundTask.sendDataToMain({
      'type': 'location_error',
      'error': error.name,
      'timestamp': now.millisecondsSinceEpoch,
    });
  }
}

Future<Position?> getSmartLocation() async {
  try {
    debugPrint("Attempting to get HIGH accuracy location...");
    final LocationSettings highSettings = Platform.isIOS
        ? AppleSettings(
            activityType: ActivityType.fitness,
            pauseLocationUpdatesAutomatically: false,
            allowBackgroundLocationUpdates: true,
            accuracy: LocationAccuracy.high,
          )
        : AndroidSettings(accuracy: LocationAccuracy.high);

    return await Geolocator.getCurrentPosition(
      locationSettings: highSettings,
    ).timeout(const Duration(seconds: 10));
  } on TimeoutException {
    debugPrint("High accuracy timed out! Falling back to MEDIUM accuracy...");

    try {
      final LocationSettings mediumSettings = Platform.isIOS
          ? AppleSettings(
              activityType: ActivityType.fitness,
              pauseLocationUpdatesAutomatically: false,
              allowBackgroundLocationUpdates: true,
              accuracy: LocationAccuracy.medium,
            )
          : AndroidSettings(accuracy: LocationAccuracy.medium);

      return await Geolocator.getCurrentPosition(
        locationSettings: mediumSettings,
      ).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      debugPrint("Medium accuracy timed out! Falling back to LOW accuracy...");

      try {
        final LocationSettings lowSettings = Platform.isIOS
            ? AppleSettings(
                activityType: ActivityType.fitness,
                pauseLocationUpdatesAutomatically: false,
                allowBackgroundLocationUpdates: true,
                accuracy: LocationAccuracy.low,
              )
            : AndroidSettings(accuracy: LocationAccuracy.low);

        return await Geolocator.getCurrentPosition(
          locationSettings: lowSettings,
        ).timeout(const Duration(seconds: 5));
      } on TimeoutException catch (e) {
        debugPrint("Even low accuracy failed: $e");

        debugPrint(
          "Absolute last resort: Returning last known cached position.",
        );
        return await Geolocator.getLastKnownPosition();
      }
    }
  } catch (e) {
    debugPrint("An unexpected error occurred: $e");
    return null;
  }
}
