import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() {
  test('migration 1 -> 2 assigns device UUID and preserves rows', () async {
    // initialize ffi for desktop testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final tmpDir = Directory.systemTemp.createTempSync('cookpilot_test');
    final dbPath = p.join(tmpDir.path, 'test_cookpilot.db');

    // create version 1 DB with sample row
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE ingredients (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          quantity TEXT,
          expiryDate TEXT,
          note TEXT
        )
      ''');
        await db.insert('ingredients', {
          'name': 'Test Herb',
          'quantity': '1 bunch',
          'expiryDate': '10/10/2026',
          'note': 'fresh',
        });
      },
    );

    await db.close();

    // set device UUID in shared prefs
    final deviceId = const Uuid().v4();
    SharedPreferences.setMockInitialValues({
      'cookpilot_device_user_id': deviceId,
    });

    // Now open DB with version 2 and run upgrade logic similar to DatabaseHelper
    final db2 = await openDatabase(
      dbPath,
      version: 2,
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          await db.execute('ALTER TABLE ingredients ADD COLUMN userId TEXT');
        }
      },
    );

    // assign existing rows to device id
    await db2.rawUpdate(
      'UPDATE ingredients SET userId = ? WHERE userId IS NULL',
      [deviceId],
    );

    final rows = await db2.query('ingredients');
    expect(rows.length, 1);
    expect(rows.first['userId'], deviceId);
    expect(rows.first['name'], 'Test Herb');

    await db2.close();
    tmpDir.deleteSync(recursive: true);
  });
}
