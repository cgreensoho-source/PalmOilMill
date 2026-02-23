import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;

  DBHelper._internal();

  factory DBHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'sampling_offline.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    // 1. Tabel Station (Master Data untuk validasi offline)
    await db.execute('''
      CREATE TABLE stations (
        station_id INTEGER PRIMARY KEY,
        station_name TEXT,
        coordinate TEXT
      )
    ''');

    // 2. Tabel Samples (Antrean Offline)
    // Kita tambah kolom 'is_synced' untuk membedakan mana yang sudah masuk ke Backend Go kamu
    await db.execute('''
      CREATE TABLE offline_samples (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        station_id INTEGER,
        sample_name TEXT,
        condition TEXT,
        created_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // 3. Tabel Images (Multiple images per sample sesuai aturanmu)
    await db.execute('''
      CREATE TABLE offline_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sample_local_id INTEGER, -- FK ke offline_samples(id)
        image_path TEXT,
        user_id INTEGER,
        FOREIGN KEY (sample_local_id) REFERENCES offline_samples (id) ON DELETE CASCADE
      )
    ''');
  }

  // Fungsi helper dasar untuk Insert/Query
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  Future<int> deleteSyncedData() async {
    final db = await database;
    return await db.delete(
      'offline_samples',
      where: 'is_synced = ?',
      whereArgs: [1],
    );
  }
}
