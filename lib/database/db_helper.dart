import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';

class DBHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'pos_database.db');
    return await openDatabase(
      path,
      version: 3, // Version 3 kar diya hai
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE customers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, phone TEXT, balance REAL DEFAULT 0)');
        await db.execute('CREATE TABLE products(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, category TEXT, purchase_price REAL, sale_price REAL, stock_qty INTEGER, low_stock_threshold INTEGER DEFAULT 5)');
        await db.execute('CREATE TABLE invoices(id INTEGER PRIMARY KEY AUTOINCREMENT, invoice_no TEXT, customer_id INTEGER, date TEXT, total_amount REAL, paid_amount REAL, status TEXT)');
        // Naya Table Hold Bills ke liye
        await db.execute('CREATE TABLE held_bills(id INTEGER PRIMARY KEY AUTOINCREMENT, customer_name TEXT, customer_phone TEXT, cart_data TEXT, date TEXT)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('CREATE TABLE products(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, category TEXT, purchase_price REAL, sale_price REAL, stock_qty INTEGER, low_stock_threshold INTEGER DEFAULT 5)');
        }
        if (oldVersion < 3) {
          await db.execute('CREATE TABLE held_bills(id INTEGER PRIMARY KEY AUTOINCREMENT, customer_name TEXT, customer_phone TEXT, cart_data TEXT, date TEXT)');
        }
      },
    );
  }

  static Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  static Future<List<Product>> getProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  static Future<int> updateStock(int productId, int newQty) async {
    final db = await database;
    return await db.update('products', {'stock_qty': newQty}, where: 'id = ?', whereArgs: [productId]);
  }
}
