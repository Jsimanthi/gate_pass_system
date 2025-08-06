import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._init();
  static Database? _database;

  LocalDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gatepass.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const scannedAtType = 'TEXT NOT NULL';

    await db.execute('''
CREATE TABLE scanned_qr_codes (
  id $idType,
  qr_code_data $textType,
  scanned_at $scannedAtType
  )
''');
  }

  Future<void> insertScannedQRCode(String qrCodeData) async {
    final db = await instance.database;
    await db.insert(
      'scanned_qr_codes',
      {'qr_code_data': qrCodeData, 'scanned_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getScannedQRCodes() async {
    final db = await instance.database;
    return await db.query('scanned_qr_codes', orderBy: 'scanned_at DESC');
  }

  Future<void> deleteScannedQRCode(int id) async {
    final db = await instance.database;
    await db.delete(
      'scanned_qr_codes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
