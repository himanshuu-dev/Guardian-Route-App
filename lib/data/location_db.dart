import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocationDatabase {
  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'locations.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: (db, _) async {
        await _createLocationsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE locations RENAME TO locations_old');
          await _createLocationsTable(db);
          await db.execute('''
            INSERT INTO locations (latitude, longitude, timestamp, error)
            SELECT latitude, longitude, timestamp, error
            FROM locations_old
          ''');
          await db.execute('DROP TABLE locations_old');
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE locations ADD COLUMN accuracy REAL',
          );
        }
      },
    );
  }

  static Future<void> _createLocationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL,
        timestamp INTEGER NOT NULL,
        error INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }
}
