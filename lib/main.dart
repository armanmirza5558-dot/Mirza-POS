import 'package:flutter/material.dart';
import 'database/db_helper.dart';
import 'screens/stock_screen.dart';
import 'models/product.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBHelper.database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    BillingScreen(),
    StockScreen(),
    Center(child: Text('Ledger - Coming Soon')),
    Center(child: Text('Expense - Coming Soon')),
    Center(child: Text('Reports - Coming Soon')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shop POS'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Billing'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Stock'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Ledger'),
          BottomNavigationBarItem(icon: Icon(Icons.payments), label: 'Expense'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
        ],
      ),
    );
  }
}

// ---------------- BILLING SCREEN ----------------
class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _searchController = TextEditingController();
  final _receivedAmountController = TextEditingController();

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Map<String, dynamic>> _cartItems = [];
  
  double _grandTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProductsForBilling();
    
    _searchController.addListener(() {
      filterProducts(_searchController.text);
    });
    
    // Jab amount receive ho to return amount calculate ho
    _receivedAmountController.addListener(() {
      setState(() {});
    });
  }

  void _loadProductsForBilling() async {
    final products = await DBHelper.getProducts();
    setState(() {
      _allProducts = products;
      _filteredProducts = products;
    });
  }

  void filterProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = [];
      });
    } else {
      setState(() {
        _filteredProducts = _allProducts
            .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  void _addProductToCart(Product product) {
    setState(() {
      int index = _cartItems.indexWhere((item) => item['product'].id == product.id);
      if (index >= 0) {
        _cartItems[index]['qty'] += 1;
      } else {
        _cartItems.add({'product': product, 'qty': 1});
      }
      _calculateTotal();
      _searchController.clear();
      _filteredProducts = [];
    });
  }

  void _calculateTotal() {
    double total = 0;
    for (var item in _cartItems) {
      total += (item['product'].salePrice * item['qty']);
    }
    setState(() {
      _grandTotal = total;
    });
  }

  Future<void> _scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        filterProducts(result.rawContent);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return amount calculation
    double received = double.tryParse(_receivedAmountController.text) ?? 0.0;
    double returnAmount = received > _grandTotal ? received - _grandTotal : 0.0;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // 1. COMPACT CUSTOMER DETAILS
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 45,
                  child: TextField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      hintText: 'Customer Name',
                      prefixIcon: Icon(Icons.person, size: 20),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 45,
                  child: TextField(
                    controller: _customerPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Phone (Optional)',
                      prefixIcon: Icon(Icons.phone, size: 20),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 2. SEARCH & SCAN
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search Product by Name...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 45,
                width: 45,
                child: IconButton(
                  icon: const Icon(Icons.qr_code_scanner, size: 24),
                  onPressed: _scanBarcode,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ],
          ),

          // Dynamic Dropdown for Search
          if (_filteredProducts.isNotEmpty && _searchController.text.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final p = _filteredProducts[index];
                  return ListTile(
                    dense: true,
                    title: Text(p.name),
                    subtitle: Text('Rs ${p.salePrice} | Stock: ${p.stockQty}'),
                    onTap: () {
                      if (p.stockQty > 0) {
                        _addProductToCart(p);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Out of stock!')),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          
          const SizedBox(height: 8),
          
          // 3. CART ITEMS LIST (Bada area)
          Expanded(
            child: _cartItems.isEmpty
                ? const Center(
                    child: Text('No items. Search to add.', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final p = item['product'] as Product;
                      final qty = item['qty'] as int;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          dense: true,
                          title: Text(p.name),
                          subtitle: Text('$qty x Rs ${p.salePrice}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Rs ${p.salePrice * qty}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _cartItems.removeAt(index);
                                    _calculateTotal();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // 4. BOTTOM CHECKOUT SECTION
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Grand Total:', style: TextStyle(fontSize: 16)),
                    Text('Rs $_grandTotal', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
                const Divider(),
                // Amount Received & Return
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _receivedAmountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Amount Received',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Return: Rs $returnAmount',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: _cartItems.isEmpty ? null : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invoice Save ka kaam ab agla step hai!')),
                      );
                    },
                    child: const Text('SAVE INVOICE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
