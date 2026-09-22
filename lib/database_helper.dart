import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'main.dart';

class DatabaseHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'mydiary.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE diaries('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'title TEXT NOT NULL, '
          'content TEXT NOT NULL, '
          'date TEXT NOT NULL, '
          'mood TEXT NOT NULL)',
        );
      },
    );
  }

  // เพิ่มบันทึก
  static Future<void> insert(Diary diary) async {
    final db = await database;
    await db.insert(
      'diaries',
      diary.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ดึงบันทึกทั้งหมด (ใหม่สุดขึ้นก่อน)
  static Future<List<Diary>> getAll() async {
    final db = await database;
    final maps = await db.query('diaries', orderBy: 'id DESC');
    return maps.map((map) => Diary.fromMap(map)).toList();
  }

  // แก้ไขบันทึก
  static Future<void> update(Diary diary) async {
    final db = await database;
    await db.update(
      'diaries',
      diary.toMap(),
      where: 'id = ?',
      whereArgs: [diary.id],
    );
  }

  // ลบบันทึก
  static Future<void> delete(int id) async {
    final db = await database;
    await db.delete('diaries', where: 'id = ?', whereArgs: [id]);
  }
}