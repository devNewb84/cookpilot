import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _databaseName = 'cookpilot.db';
  static const _databaseVersion = 1;
  static const ingredientTable = 'ingredients';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);
    print("SQLite path: $path");
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $ingredientTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        quantity TEXT,
        expiryDate TEXT,
        note TEXT
      )
    ''');
  }

  Future<int> insertIngredient(Map<String, dynamic> ingredient) async {
    final db = await database;
    return await db.insert(ingredientTable, ingredient);
  }

  Future<List<Map<String, dynamic>>> getIngredients() async {
    final db = await database;
    return await db.query(ingredientTable, orderBy: 'id DESC');
  }

  Future<int> deleteIngredient(int id) async {
    final db = await database;
    return await db.delete(ingredientTable, where: 'id = ?', whereArgs: [id]);
  }
}
