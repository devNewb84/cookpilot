import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'ingredient_repository.dart';

class DatabaseHelper implements IngredientRepository {
  static const _databaseName = 'cookpilot.db';
  // bumped to 2 to add userId and migration
  static const _databaseVersion = 2;
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
    // debug: database path
    // Do not log production-sensitive data; use debugPrint if needed.
    print("SQLite path: $path");

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $ingredientTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        quantity TEXT,
        expiryDate TEXT,
        note TEXT,
        userId TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add userId column if it doesn't exist yet.
      await db.execute('ALTER TABLE $ingredientTable ADD COLUMN userId TEXT');
      // Note: assigning existing rows to device userId is handled by caller
      // because we need access to AuthService to get the device UUID.
    }
  }

  @override
  Future<int> insertIngredient(Map<String, dynamic> ingredient) async {
    final db = await database;
    return await db.insert(ingredientTable, ingredient);
  }

  @override
  Future<List<Map<String, dynamic>>> getIngredients(
    String currentUserId,
  ) async {
    final db = await database;
    return await db.query(
      ingredientTable,
      where: 'userId = ?',
      whereArgs: [currentUserId],
      orderBy: 'id DESC',
    );
  }

  @override
  Future<int> deleteIngredient(int id, String currentUserId) async {
    final db = await database;
    return await db.delete(
      ingredientTable,
      where: 'id = ? AND userId = ?',
      whereArgs: [id, currentUserId],
    );
  }
}
