// lib/services/database_service.dart

import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../models/stop.dart';
import '../models/route.dart'; // for RouteModel

class DatabaseService {
  static Database? _db;

  /// Bump this every time you change schema in onCreate/onUpgrade
  static const _dbVersion = 2;

  static Future<Database> _openDatabase() async {
    if (_db != null) return _db!;

    final databasesPath = await getDatabasesPath();
    final dbPath = p.join(databasesPath, 'ctfo_demo.db');

    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        // 1) Stops table (now with photorequired, side, custsvc, notes)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Stops (
            id            INTEGER PRIMARY KEY,
            routeId       TEXT,
            sequence      INTEGER,
            name          TEXT,
            address       TEXT,
            completed     INTEGER,
            uploaded      INTEGER,
            completedAt   TEXT,
            latitude      REAL,
            longitude     REAL,
            photorequired INTEGER NOT NULL DEFAULT 0,
            side          TEXT,
            custsvc       TEXT,
            notes         TEXT
          )
        ''');

        // 2) RouteCache
        await _createRouteCacheTableIfNeeded(db);

        // 3) Import tables
        await db.execute('''
          CREATE TABLE IF NOT EXISTS routelist (
            routeid TEXT,
            jobid TEXT,
            jobdetailid TEXT,
            interfacetype TEXT,
            city TEXT,
            state TEXT,
            zip TEXT,
            datevalidfrom INTEGER,
            datevalidto INTEGER,
            datevalidfromsoft INTEGER,
            datevalidtosoft INTEGER,
            lookaheadforward INTEGER,
            lookaheadside INTEGER,
            deliveryforward INTEGER,
            deliveryside INTEGER,
            routetype TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS streetsummarylist (
            summaryid TEXT PRIMARY KEY,
            jobdetailid TEXT,
            streetname TEXT,
            lat REAL,
            "long" REAL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS addressdetaillist (
            jobdetailid TEXT,
            summaryid TEXT,
            deliveryid TEXT PRIMARY KEY,
            streetaddress TEXT,
            searchaddress TEXT,
            addressnumber TEXT,
            qty INTEGER,
            lat REAL,
            "long" REAL,
            sequence INTEGER,
            jobtype TEXT,
            custsvc TEXT,
            notes TEXT,
            side TEXT,
            photorequired INTEGER
          )
        ''');

        // ← NEW: products table
        await _createAddressDetailProductsTableIfNeeded(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // add each new column to existing Stops table
          await db.execute('ALTER TABLE Stops ADD COLUMN photorequired INTEGER NOT NULL DEFAULT 0;');
          await db.execute('ALTER TABLE Stops ADD COLUMN side TEXT;');
          await db.execute('ALTER TABLE Stops ADD COLUMN custsvc TEXT;');
          await db.execute('ALTER TABLE Stops ADD COLUMN notes TEXT;');
        }
        // future migrations go here...
      },
      onOpen: (db) async {
        // Ensure auxiliary tables exist
        await _createRouteCacheTableIfNeeded(db);
        await _createAddressDetailProductsTableIfNeeded(db);
      },
    );

    return _db!;
  }

  /// Creates RouteCache table if not present
  static Future<void> _createRouteCacheTableIfNeeded(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS RouteCache (
        routeId TEXT PRIMARY KEY,
        encodedPolyline TEXT
      )
    ''');
  }

  /// Creates addressdetailproducts table if not present
  static Future<void> _createAddressDetailProductsTableIfNeeded(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS addressdetailproducts (
        productcode TEXT,
        qty INTEGER,
        deliveryid TEXT,
        jobdetailid TEXT
      )
    ''');
  }

  // ---------------------------------------------------------------------------
  //  POLYLINE CACHE METHODS
  // ---------------------------------------------------------------------------
  static Future<void> saveRoutePolyline({
    required String routeId,
    required String encodedPolyline,
  }) async {
    final db = await _openDatabase();
    await db.insert(
      'RouteCache',
      {
        'routeId': routeId,
        'encodedPolyline': encodedPolyline,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> getRoutePolyline(String routeId) async {
    final db = await _openDatabase();
    final rows = await db.query(
      'RouteCache',
      where: 'routeId = ?',
      whereArgs: [routeId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['encodedPolyline'] as String?;
  }

  // ---------------------------------------------------------------------------
  //  IMPORT A DEMO FILE => DB
  // ---------------------------------------------------------------------------
  static Future<void> importDemoFile(String fileName) async {
    final db = await _openDatabase();

    // Load the .txt from assets
    final sqlScript = await rootBundle.loadString(fileName);
    final statements = sqlScript.split(';');

    for (var rawStmt in statements) {
      final stmt = rawStmt.trim();
      if (stmt.isEmpty) continue;
      final upper = stmt.toUpperCase();
      if (upper.contains('^*^') ||
          upper.startsWith('BEGIN') ||
          upper.startsWith('COMMIT') ||
          (upper.contains('DELETED') && upper.contains('ROUTELIST'))) {
        continue;
      }
      try {
        await db.execute(stmt);
      } catch (e) {
        print('Error executing SQL: $e\nStatement: $stmt');
      }
    }

    // Convert addressdetaillist → Stops
    final addressRows = await db.query('addressdetaillist');
    for (var row in addressRows) {
      try {
        int stopId = int.tryParse(row['deliveryid'].toString()) ?? 0;
        int routeId = int.tryParse(row['jobdetailid'].toString()) ?? 0;
        int sequence = int.tryParse(row['sequence'].toString()) ?? 0;
        String name = row['streetaddress']?.toString() ?? '';
        String address = row['searchaddress']?.toString() ?? '';
        double? lat = row['lat'] != null ? double.tryParse(row['lat'].toString()) : null;
        double? lng = row['long'] != null ? double.tryParse(row['long'].toString()) : null;

        final stop = Stop(
          id: stopId,
          routeId: routeId,
          sequence: sequence,
          name: name,
          address: address,
          completed: false,
          uploaded: false,
          completedAt: null,
          latitude: lat,
          longitude: lng,
        );

        await db.insert(
          'Stops',
          stop.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        print('Error inserting stop from $fileName: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  //  CLEAR + STOP QUERIES
  // ---------------------------------------------------------------------------
  static Future<void> clearAllData() async {
    final db = await _openDatabase();
    await db.delete('Stops');
  }

  static Future<void> insertStops(String routeId, List<Stop> stops) async {
    final db = await _openDatabase();
    for (var s in stops) {
      await db.insert(
        'Stops',
        s.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<void> updateStopSequence(List<Stop> stops) async {
    final db = await _openDatabase();
    await db.transaction((txn) async {
      for (final stop in stops) {
        await txn.update(
          'Stops',
          {'sequence': stop.sequence},
          where: 'id = ?',
          whereArgs: [stop.id],
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  //  BARCODE / PHOTO / SIGNATURE QUERIES
  // ---------------------------------------------------------------------------
  static Future<void> insertBarcodeScan({
    required int stopId,
    required String code,
    required String type,
  }) async {
    final db = await _openDatabase();
    await db.execute('''
      CREATE TABLE IF NOT EXISTS BarcodeScans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stopId INTEGER,
        code TEXT,
        type TEXT,
        timestamp TEXT
      )
    ''');
    await db.insert('BarcodeScans', {
      'stopId': stopId,
      'code': code,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> insertPhoto({
    required int stopId,
    required String filePath,
    double? latitude,
    double? longitude,
  }) async {
    final db = await _openDatabase();
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stopId INTEGER,
        filePath TEXT,
        timestamp TEXT,
        latitude REAL,
        longitude REAL
      )
    ''');
    await db.insert('Photos', {
      'stopId': stopId,
      'filePath': filePath,
      'timestamp': DateTime.now().toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  static Future<void> insertSignature({
    required int stopId,
    required String filePath,
    required String signerName,
  }) async {
    final db = await _openDatabase();
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Signatures (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stopId INTEGER,
        filePath TEXT,
        signerName TEXT,
        timestamp TEXT
      )
    ''');
    await db.insert('Signatures', {
      'stopId': stopId,
      'filePath': filePath,
      'signerName': signerName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Updates the main Stops row with camera-captured coords
  static Future<void> updateStopLocation(
    int stopId,
    double latitude,
    double longitude,
  ) async {
    final db = await _openDatabase();
    await db.update(
      'Stops',
      {
        'latitude': latitude,
        'longitude': longitude,
      },
      where: 'id = ?',
      whereArgs: [stopId],
    );
  }

  // ---------------------------------------------------------------------------
  //  STOP "DELIVERED" UPDATE
  // ---------------------------------------------------------------------------
  static Future<void> updateStopDelivered(Stop stop) async {
    final db = await _openDatabase();
    final updated = {
      'completed': stop.completed ? 1 : 0,
      'uploaded': stop.uploaded ? 1 : 0,
      'completedAt': stop.completedAt?.toIso8601String(),
    };
    await db.update(
      'Stops',
      updated,
      where: 'id = ?',
      whereArgs: [stop.id],
    );
  }

  // ---------------------------------------------------------------------------
  //  GET STOPS / GET ROUTES
  // ---------------------------------------------------------------------------
  static Future<List<Stop>> getStops([String? routeId]) async {
    final db = await _openDatabase();
    String? whereClause;
    List<Object?>? whereArgs;
    if (routeId != null) {
      whereClause = 'routeId = ?';
      whereArgs = [routeId];
    }
    final maps = await db.query(
      'Stops',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'sequence ASC',
    );
    return maps.map((m) => Stop.fromJson(m)).toList();
  }

  static Future<List<RouteModel>> getRoutes() async {
    final db = await _openDatabase();
    final maps = await db.query('routelist');
    return maps.map((m) => RouteModel.fromMap(m)).toList();
  }
}
