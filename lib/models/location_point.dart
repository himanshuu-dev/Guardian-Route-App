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

  Map<String, dynamic> toMap() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'error': error.index,
      };

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      id: map['id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      timestamp:
          DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      error: LocationError.values[map['error']],
    );
  }
}
