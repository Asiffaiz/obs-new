import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:voicealerts_obs/features/bussiness%20card/domain/models/business_card_model.dart';



class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'business_cards.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE business_cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        company TEXT NOT NULL,
        jobTitle TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        email TEXT NOT NULL,
        website TEXT,
        address TEXT,
        imagePath TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertBusinessCard(BusinessCard businessCard) async {
    Database db = await database;
    return await db.insert('business_cards', businessCard.toMap());
  }

  Future<List<BusinessCard>> getAllBusinessCards() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'business_cards',
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) {
      return BusinessCard.fromMap(maps[i]);
    });
  }

  Future<BusinessCard?> getBusinessCard(int id) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'business_cards',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return BusinessCard.fromMap(maps.first);
    }
    return null;
  }

  Future<List<BusinessCard>> searchBusinessCards(String query) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'business_cards',
      where: 'name LIKE ? OR company LIKE ? OR email LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return BusinessCard.fromMap(maps[i]);
    });
  }

  Future<int> updateBusinessCard(BusinessCard businessCard) async {
    Database db = await database;
    return await db.update(
      'business_cards',
      businessCard.toMap(),
      where: 'id = ?',
      whereArgs: [businessCard.id],
    );
  }

  Future<int> deleteBusinessCard(int id) async {
    Database db = await database;
    return await db.delete('business_cards', where: 'id = ?', whereArgs: [id]);
  }
}
