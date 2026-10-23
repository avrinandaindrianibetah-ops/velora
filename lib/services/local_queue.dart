import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalQueue {
  static Database? _db;
  static Future<Database> get db async => _db ??= await openDatabase(
        p.join(await getDatabasesPath(), 'velora.db'),
        version: 1,
        onCreate: (d, _) => d.execute('CREATE TABLE queue(id TEXT PRIMARY KEY, uid TEXT, kode_mk TEXT, '
            'mata_kuliah TEXT, tanggal TEXT, lat REAL, lng REAL, foto_path TEXT, '
            'device_uuid TEXT, waktu_lokal INTEGER)'),
      );
  static Future<void> put(Map<String, Object?> row) async =>
      (await db).insert('queue', row, conflictAlgorithm: ConflictAlgorithm.replace);
  static Future<List<Map<String, Object?>>> all(String uid) async =>
      (await db).query('queue', where: 'uid=?', whereArgs: [uid]);
  static Future<void> remove(String id) async =>
      (await db).delete('queue', where: 'id=?', whereArgs: [id]);
  static Future<int> count() async =>
      Sqflite.firstIntValue(await (await db).rawQuery('SELECT COUNT(*) FROM queue')) ?? 0;
}