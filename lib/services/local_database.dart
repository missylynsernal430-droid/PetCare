import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final databasePath = path.join(await getDatabasesPath(), 'petcare.db');
    _database = await openDatabase(
      databasePath,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pets (
            id TEXT PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL,
            age INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE feedings (
            id TEXT PRIMARY KEY, petId TEXT NOT NULL, timeMinutes INTEGER NOT NULL,
            note TEXT NOT NULL, isEnabled INTEGER NOT NULL DEFAULT 1,
            FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE health_reminders (
            id TEXT PRIMARY KEY, petId TEXT NOT NULL, title TEXT NOT NULL,
            scheduledAt TEXT NOT NULL, notes TEXT NOT NULL,
            FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE grooming_logs (
            id TEXT PRIMARY KEY, petId TEXT NOT NULL, type TEXT NOT NULL,
            date TEXT NOT NULL, notes TEXT NOT NULL, repeatDays INTEGER,
            FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE care_tasks (
            id TEXT PRIMARY KEY, petId TEXT NOT NULL, title TEXT NOT NULL,
            notes TEXT NOT NULL, isCompleted INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL,
            FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE
          )
        ''');
      },
    );
    return _database!;
  }

  Future<List<Map<String, Object?>>> readAll(String table) async {
    final db = await database;
    return db.query(table);
  }

  Future<void> insert(String table, Map<String, Object?> values) async {
    final db = await database;
    await db.insert(
      table,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(String table, Map<String, Object?> values) async {
    final db = await database;
    await db.update(table, values, where: 'id = ?', whereArgs: [values['id']]);
  }

  Future<void> delete(String table, String id) async {
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
