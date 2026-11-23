import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
      version: 1,
      onCreate: (db, version) async {
        // Customer Table
        await db.execute('''
          CREATE TABLE customers(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            phone TEXT,
            balance REAL DEFAULT 0
          )
        ''');
        
        // Products Table
        await db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            category TEXT,
            purchase_price REAL,
            sale_price REAL,
            stock_qty INTEGER,
            low_stock_threshold INTEGER DEFAULT 5
          )
        ''');
        
        // Invoices Table
        await db.execute('''
          CREATE TABLE invoices(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            invoice_no TEXT,
            customer_id INTEGER,
            date TEXT,
            total_amount REAL,
            paid_amount REAL,
            status TEXT
          )
        ''');
      },
    );
  }
}
