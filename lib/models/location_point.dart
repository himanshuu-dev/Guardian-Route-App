enum LocationError {
  none,
  gpsDisabled,
  permissionDenied,
}

class LocationPoint {
  final int? id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final LocationError error;

  LocationPoint({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.error = LocationError.none,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
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
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      error: LocationError.values[map['error'] as int],
    );
  }
}
