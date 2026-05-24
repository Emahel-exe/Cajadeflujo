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
      version: 1,
      onCreate: _createDB,
    );
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

    // Insert default categories/rows matching the initial layout
    final defaultRows = [
      {
        'label': 'Sueldo',
        'group_type': 'income',
        'values': [1850000, 1850000, 1850000, 1850000, 1900000, 1900000, 1900000, 1900000, 1950000, 1950000, 1950000, 1950000]
      },
      {
        'label': 'Freelance / otros',
        'group_type': 'income',
        'values': [250000, 180000, 300000, 220000, 250000, 280000, 260000, 300000, 320000, 280000, 300000, 350000]
      },
      {
        'label': 'Arriendo / dividendo',
        'group_type': 'fixedExpense',
        'values': List.filled(12, 620000)
      },
      {
        'label': 'Servicios basicos',
        'group_type': 'fixedExpense',
        'values': List.filled(12, 95000)
      },
      {
        'label': 'Internet y telefono',
        'group_type': 'fixedExpense',
        'values': List.filled(12, 54000)
      },
      {
        'label': 'Seguros / suscripciones',
        'group_type': 'fixedExpense',
        'values': List.filled(12, 78000)
      },
      {
        'label': 'Transporte',
        'group_type': 'variableExpense',
        'values': [120000, 115000, 130000, 125000, 110000, 120000, 135000, 140000, 125000, 120000, 130000, 150000]
      },
      {
        'label': 'Comida',
        'group_type': 'variableExpense',
        'values': [360000, 340000, 380000, 370000, 365000, 390000, 410000, 400000, 380000, 390000, 420000, 460000]
      },
      {
        'label': 'Salud',
        'group_type': 'variableExpense',
        'values': [40000, 55000, 35000, 80000, 45000, 50000, 65000, 45000, 55000, 70000, 50000, 60000]
      },
      {
        'label': 'Ocio / regalos',
        'group_type': 'variableExpense',
        'values': [90000, 120000, 110000, 95000, 100000, 130000, 150000, 135000, 120000, 125000, 160000, 220000]
      },
    ];

    for (final row in defaultRows) {
      final values = row['values'] as List<int>;
      final map = {
        'label': row['label'] as String,
        'group_type': row['group_type'] as String,
        'control_value': 0,
      };
      for (var i = 0; i < 12; i++) {
        map['val_$i'] = values[i];
      }
      await db.insert('cash_flow_rows', map);
    }
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
}
