import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final _databaseName = "timekeeping.db";
  static final _databaseVersion = 1;

  static final menuTable = 'menu_table';
  static final timeKeepingTable = 'timekeeping_table';

  static final columnId = '_id';
  static final columnValue = 'value';
  static final columnOriginalTime = 'original_time';
  static final columnCurrentTime = 'current_time';

  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(
      "CREATE TABLE $menuTable($columnId INTEGER PRIMARY KEY, $columnValue TEXT NOT NULL)",
    );
    await db.execute(
      "CREATE TABLE $timeKeepingTable($columnId INTEGER PRIMARY KEY, $columnValue TEXT NOT NULL, $columnOriginalTime TEXT, $columnCurrentTime TEXT)",
    );
  }

  String get menuTableName => menuTable;

  String get timeKeepingTableName => timeKeepingTable;

  // Common query

  Future<int> insert(String table, Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> queryRowCount(String table) async {
    Database db = await instance.database;
    return Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $table'));
  }

  Future<int> update(String table, Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAllData(String table) async {
    Database db = await instance.database;
    return await db.query(table);
  }
}
