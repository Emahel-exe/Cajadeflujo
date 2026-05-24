import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cash_flow.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS parameters');
      await db.execute('DROP TABLE IF EXISTS cash_flow_rows');
      await _createDB(db, newVersion);
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Create parameters table
    await db.execute('''
      CREATE TABLE parameters (
        id INTEGER PRIMARY KEY,
        cash INTEGER DEFAULT 0,
        bank INTEGER DEFAULT 0,
        objective INTEGER DEFAULT 0
      )
    ''');

    // Insert initial parameters
    await db.insert('parameters', {
      'id': 1,
      'cash': 0,
      'bank': 0,
      'objective': 0,
    });

    // Create cash_flow_rows table
    await db.execute('''
      CREATE TABLE cash_flow_rows (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        label TEXT,
        group_type TEXT,
        val_0 INTEGER DEFAULT 0,
        val_1 INTEGER DEFAULT 0,
        val_2 INTEGER DEFAULT 0,
        val_3 INTEGER DEFAULT 0,
        val_4 INTEGER DEFAULT 0,
        val_5 INTEGER DEFAULT 0,
        val_6 INTEGER DEFAULT 0,
        val_7 INTEGER DEFAULT 0,
        val_8 INTEGER DEFAULT 0,
        val_9 INTEGER DEFAULT 0,
        val_10 INTEGER DEFAULT 0,
        val_11 INTEGER DEFAULT 0,
        control_value INTEGER DEFAULT 0
      )
    ''');
  }

  // Load all parameters
  Future<Map<String, int>> loadParameters() async {
    final db = await instance.database;
    final maps = await db.query('parameters', where: 'id = ?', whereArgs: [1]);
    if (maps.isNotEmpty) {
      final map = maps.first;
      return {
        'cash': map['cash'] as int? ?? 0,
        'bank': map['bank'] as int? ?? 0,
        'objective': map['objective'] as int? ?? 0,
      };
    }
    return {'cash': 0, 'bank': 0, 'objective': 0};
  }

  // Save specific parameter
  Future<void> saveParameter(String key, int value) async {
    final db = await instance.database;
    await db.update(
      'parameters',
      {key: value},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // Load all rows
  Future<List<Map<String, dynamic>>> loadRows() async {
    final db = await instance.database;
    return await db.query('cash_flow_rows', orderBy: 'id ASC');
  }

  // Save specific row's month value
  Future<void> saveRowMonthValue(int id, int monthIndex, int value) async {
    final db = await instance.database;
    await db.update(
      'cash_flow_rows',
      {'val_$monthIndex': value},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Save specific row's control value
  Future<void> saveRowControlValue(int id, int value) async {
    final db = await instance.database;
    await db.update(
      'cash_flow_rows',
      {'control_value': value},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Reset all data
  Future<void> resetAllData() async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.update(
        'parameters',
        {'cash': 0, 'bank': 0, 'objective': 0},
        where: 'id = ?',
        whereArgs: [1],
      );

      final updateMap = <String, dynamic>{
        'control_value': 0,
      };
      for (var i = 0; i < 12; i++) {
        updateMap['val_$i'] = 0;
      }
      await txn.update('cash_flow_rows', updateMap);
    });
  }

  // Insert a new row
  Future<int> insertRow(String label, String groupType) async {
    final db = await instance.database;
    final map = {
      'label': label,
      'group_type': groupType,
      'control_value': 0,
    };
    for (var i = 0; i < 12; i++) {
      map['val_$i'] = 0;
    }
    return await db.insert('cash_flow_rows', map);
  }

  // Delete a row
  Future<int> deleteRow(int id) async {
    final db = await instance.database;
    return await db.delete(
      'cash_flow_rows',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
