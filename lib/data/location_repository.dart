import 'dart:async';
import 'location_db.dart';
import '../models/location_point.dart';

class LocationRepository {
  final _controller = StreamController<List<LocationPoint>>.broadcast();
  final bool _enablePolling;
  Timer? _pollTimer;

  LocationRepository({bool enablePolling = true})
      : _enablePolling = enablePolling {
    if (_enablePolling) {
      _startPolling();
    }
  }

  /// WRITE: Used by background service
  Future<void> insert(LocationPoint point) async {
    final db = await LocationDatabase.instance;
    await db.insert('locations', point.toMap());
  }

  /// READ: Used by UI (polling)
  void _startPolling() {
    _emitLatest();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await _emitLatest();
    });
  }

  Future<void> _emitLatest() async {
    try {
      final db = await LocationDatabase.instance;
      final rows = await db.query(
        'locations',
        orderBy: 'timestamp DESC',
        limit: 10,
      );

      _controller.add(rows.map(LocationPoint.fromMap).toList());
    } catch (error, stackTrace) {
      _controller.addError(error, stackTrace);
    }
  }

  Stream<List<LocationPoint>> watchRecent() => _controller.stream;

  void dispose() {
    _pollTimer?.cancel();
    _controller.close();
  }
}
