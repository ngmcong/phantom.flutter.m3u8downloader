import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';

import 'dataentities.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('download_queue.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Khởi tạo factory nếu chạy trên Desktop
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
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

  // Tạo bảng dữ liệu
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE download_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT,
        url TEXT,
        size REAL,
        status TEXT,
        downloadedSize REAL,
        referer TEXT,
        numberOfOffset INTEGER,
        currentOffset INTEGER
      )
    ''');
  }

  // 1. Thêm mới
  Future<int> insertItem(DataDownloadQueue item) async {
    final db = await instance.database;
    return await db.insert('download_queue', item.toMap());
  }

  // 2. Lấy toàn bộ danh sách
  Future<List<DataDownloadQueue>> getAllItems() async {
    final db = await instance.database;
    final result = await db.query('download_queue');
    return result.map((json) => DataDownloadQueue.fromMap(json)).toList();
  }

  // 3. Cập nhật tiến độ tải/trạng thái
  Future<int> updateItem(DataDownloadQueue item) async {
    final db = await instance.database;
    return await db.update(
      'download_queue',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // 4. Xóa item
  Future<int> deleteItem(int id) async {
    final db = await instance.database;
    return await db.delete(
      'download_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
