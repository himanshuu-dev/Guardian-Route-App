enum LocationError {
  none,
  gpsDisabled,
  permissionDenied,
}

enum LocationAccuracyLevel {
  unknown,
  low,
  medium,
  high,
}

class LocationPoint {
  final int? id;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;
  final LocationError error;

  LocationPoint({
    this.id,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.timestamp,
    this.error = LocationError.none,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'error': error.index,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      id: map['id'],
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      error: LocationError.values[map['error'] as int],
    );
  }

  LocationAccuracyLevel get accuracyLevel {
    if (error != LocationError.none || accuracy == null) {
      return LocationAccuracyLevel.unknown;
    }
    if (accuracy! <= 20) return LocationAccuracyLevel.high;
    if (accuracy! <= 100) return LocationAccuracyLevel.medium;
    return LocationAccuracyLevel.low;
  }

  String get accuracyLabel => accuracyLevel.name;
}
