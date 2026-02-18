import 'dart:async';
import 'location_db.dart';
import '../models/location_point.dart';

class LocationRepository {
  final _controller = StreamController<List<LocationPoint>>.broadcast();
  Timer? _pollTimer;

  LocationRepository() {
    _startPolling();
  }

  /// WRITE: Used by background service
  Future<void> insert(LocationPoint point) async {
    final db = await LocationDatabase.instance;
    await db.insert('locations', point.toMap());
  }

  /// READ: Used by UI (polling)
  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final db = await LocationDatabase.instance;
      final rows = await db.query(
        'locations',
        orderBy: 'timestamp DESC',
        limit: 10,
      );

      _controller.add(rows.map(LocationPoint.fromMap).toList());
    });
  }

  Stream<List<LocationPoint>> watchRecent() => _controller.stream;

  void dispose() {
    _pollTimer?.cancel();
    _controller.close();
  }
}
