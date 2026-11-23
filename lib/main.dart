import 'package:flutter/material.dart';
import 'database/db_helper.dart';
import 'screens/stock_screen.dart';
import 'models/product.dart';

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
  
  // Bill items store karne ke liye
  List<Map<String, dynamic>> _cartItems = [];
  List<Product> _availableProducts = [];
  
  double _grandTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProductsForBilling();
  }

  void _loadProductsForBilling() async {
    final products = await DBHelper.getProducts();
    setState(() {
      _availableProducts = products;
    });
  }

  void _addProductToCart(Product product) {
    setState(() {
      // Check if product already in cart
      int index = _cartItems.indexWhere((item) => item['product'].id == product.id);
      if (index >= 0) {
        _cartItems[index]['qty'] += 1;
      } else {
        _cartItems.add({
          'product': product,
          'qty': 1,
        });
      }
      _calculateTotal();
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

  void _showProductSelectionDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: _availableProducts.isEmpty
                    ? const Center(child: Text('No products available. Add stock first.'))
                    : ListView.builder(
                        itemCount: _availableProducts.length,
                        itemBuilder: (context, index) {
                          final p = _availableProducts[index];
                          return ListTile(
                            title: Text(p.name),
                            subtitle: Text('Price: Rs ${p.salePrice} | Stock: ${p.stockQty}'),
                            onTap: () {
                              if (p.stockQty > 0) {
                                _addProductToCart(p);
                                Navigator.pop(context);
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
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Details Form
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  TextField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name (Optional)',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customerPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number (Optional)',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Add Product Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showProductSelectionDialog,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add Product to Bill', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Cart Items List
          Expanded(
            child: _cartItems.isEmpty
                ? const Center(child: Text('No items in bill'))
                : ListView.builder(
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final p = item['product'] as Product;
                      final qty = item['qty'] as int;
                      return Card(
                        child: ListTile(
                          title: Text(p.name),
                          subtitle: Text('Qty: $qty x Rs ${p.salePrice}'),
                          trailing: Text(
                            'Rs ${p.salePrice * qty}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Grand Total & Save Button
          Container(
            padding: const EdgeInsets.all(16),
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
                    const Text('Grand Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Rs $_grandTotal', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _cartItems.isEmpty ? null : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invoice Save ka function agla step hai!')),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('Save Invoice', style: TextStyle(fontSize: 18)),
                    ),
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
