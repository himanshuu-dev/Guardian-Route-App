import 'dart:async';
import 'location_db.dart';
import '../models/location_point.dart';

class LocationRepository {
  final _controller = StreamController<List<LocationPoint>>.broadcast();

  LocationRepository() {
    _emitRecent();
  }

  Future<void> insert(LocationPoint point) async {
    final db = await LocationDatabase.instance;
    await db.insert('locations', point.toMap());
    await _emitRecent();
  }

  Future<void> _emitRecent() async {
    final db = await LocationDatabase.instance;

    final rows = await db.query(
      'locations',
      orderBy: 'timestamp DESC',
      limit: 10,
    );

    _controller.add(rows.map(LocationPoint.fromMap).toList());
  }

  Stream<List<LocationPoint>> watchRecent() => _controller.stream;
}
