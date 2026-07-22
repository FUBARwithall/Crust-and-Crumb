import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/bakery_item.dart';
import '../models/order_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (kIsWeb) {
      // sqflite native C binaries are not directly supported on web without FFI workers
      return null;
    }
    if (_database != null) return _database!;

    try {
      _database = await _initDB('bakery_app.db');
      return _database;
    } catch (e) {
      debugPrint('[DatabaseHelper] SQLite init error: $e');
      return null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Table 1: Products
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        image TEXT NOT NULL,
        description TEXT NOT NULL,
        is_available INTEGER NOT NULL
      )
    ''');

    // Table 2: Orders
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        customer_name TEXT NOT NULL,
        customer_phone TEXT NOT NULL,
        address_notes TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        shipping_method TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        total_price REAL NOT NULL,
        items_json TEXT NOT NULL,
        order_time TEXT NOT NULL
      )
    ''');
  }

  // --- PRODUCT OPERATIONS ---

  Future<void> saveProducts(List<BakeryItem> products) async {
    final db = await database;
    if (db == null) return;

    try {
      final batch = db.batch();
      for (final item in products) {
        batch.insert(
          'products',
          {
            'id': item.id,
            'name': item.name,
            'category': item.category.name,
            'price': item.price,
            'image': item.imageUrl,
            'description': item.description,
            'is_available': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      debugPrint('[DatabaseHelper] Saved ${products.length} products to SQLite');
    } catch (e) {
      debugPrint('[DatabaseHelper] saveProducts error: $e');
    }
  }

  Future<List<BakeryItem>> getProducts() async {
    final db = await database;
    if (db == null) return [];

    try {
      final maps = await db.query('products');
      if (maps.isEmpty) return [];

      return maps.map((map) {
        final catStr = map['category'] as String? ?? 'roti';
        return BakeryItem(
          id: map['id'] as String,
          name: map['name'] as String,
          category: catStr == 'kue' ? BakeryCategory.kue : BakeryCategory.roti,
          price: (map['price'] as num).toDouble(),
          imageUrl: map['image'] as String? ?? '',
          description: map['description'] as String? ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('[DatabaseHelper] getProducts error: $e');
      return [];
    }
  }

  // --- ORDER OPERATIONS ---

  Future<void> saveOrder(OrderModel order) async {
    final db = await database;
    if (db == null) return;

    try {
      final itemsJson = jsonEncode(order.items.map((e) => e.toJson()).toList());

      await db.insert(
        'orders',
        {
          'id': order.id,
          'customer_name': order.customerName,
          'customer_phone': order.customerPhone,
          'address_notes': order.addressNotes,
          'latitude': order.latitude,
          'longitude': order.longitude,
          'shipping_method': order.shippingMethod,
          'payment_method': order.paymentMethod,
          'total_price': order.totalPrice,
          'items_json': itemsJson,
          'order_time': order.orderTime.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('[DatabaseHelper] Saved order ${order.id} to SQLite');
    } catch (e) {
      debugPrint('[DatabaseHelper] saveOrder error: $e');
    }
  }

  Future<List<OrderModel>> getOrders() async {
    final db = await database;
    if (db == null) return [];

    try {
      final maps = await db.query('orders', orderBy: 'order_time DESC');
      if (maps.isEmpty) return [];

      return maps.map((map) {
        final List<dynamic> itemsList = jsonDecode(map['items_json'] as String);
        final items = itemsList
            .map((e) => OrderCartItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        return OrderModel(
          id: map['id'] as String,
          customerName: map['customer_name'] as String,
          customerPhone: map['customer_phone'] as String,
          addressNotes: map['address_notes'] as String,
          latitude: (map['latitude'] as num).toDouble(),
          longitude: (map['longitude'] as num).toDouble(),
          shippingMethod: map['shipping_method'] as String,
          paymentMethod: map['payment_method'] as String,
          items: items,
          totalPrice: (map['total_price'] as num).toDouble(),
          orderTime: DateTime.parse(map['order_time'] as String),
        );
      }).toList();
    } catch (e) {
      debugPrint('[DatabaseHelper] getOrders error: $e');
      return [];
    }
  }
}
