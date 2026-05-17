import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

/// Manages the SQLite database connection and initialization.
/// Handles the initial copying of the pre-populated database from assets.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Provides access to the database, initializing it if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('wordnext.db');
    return _database!;
  }

  /// Initializes the database by copying it from assets if it doesn't exist in the local storage.
  Future<Database> _initDB(String fileName) async {
    String path;
    if (Platform.isWindows) {
      final docDir = await getApplicationDocumentsDirectory();
      path = join(docDir.path, 'WordNext', fileName);
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, fileName);
    }

    // Check if the database already exists in the device's storage
    final exists = await databaseExists(path);

    if (!exists) {
      try {
        // Ensure the directory exists before copying
        await Directory(dirname(path)).create(recursive: true);
        
        // Load the database file from the application's assets
        ByteData data = await rootBundle.load("assets/$fileName");
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        
        // Write the database file to the local storage
        await File(path).writeAsBytes(bytes, flush: true);
        print("Database successfully copied from assets.");
      } catch (e) {
        throw Exception("Failed to copy database from assets: $e");
      }
    }

    // Open the local database file
    return await openDatabase(path);
  }
}