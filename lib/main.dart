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

// ---------------- BILLING SCREEN (Candela Style) ----------------
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
  bool _isReturnMode = false; // Return Mode ka toggle

  @override
  void initState() {
    super.initState();
    _loadProducts();
    
    _searchController.addListener(() {
      filterProducts(_searchController.text);
    });
    
    _receivedAmountController.addListener(() {
      setState(() {});
    });
  }

  void _loadProducts() async {
    final products = await DBHelper.getProducts();
    setState(() {
      _allProducts = products;
      _filteredProducts = products;
    });
  }

  void filterProducts(String query) {
    if (query.isEmpty) {
      setState(() => _filteredProducts = []);
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
      // Agar return mode on hai to quantity minus mein jayegi
      int qtyToAdd = _isReturnMode ? -1 : 1;
      
      int index = _cartItems.indexWhere((item) => item['product'].id == product.id);
      if (index >= 0) {
        _cartItems[index]['qty'] += qtyToAdd;
        // Agar qty 0 ho jaye to item hata dein
        if (_cartItems[index]['qty'] == 0) {
          _cartItems.removeAt(index);
        }
      } else {
        _cartItems.add({'product': product, 'qty': qtyToAdd});
      }
      
      _calculateTotal();
      _searchController.clear();
      _filteredProducts = [];
    });
  }

  // Price Edit karne ka function
  void _editPrice(int index) {
    TextEditingController priceController = TextEditingController(
      text: _cartItems[index]['product'].salePrice.toString()
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Price'),
          content: TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'New Price', prefixText: 'Rs '),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                double? newPrice = double.tryParse(priceController.text);
                if (newPrice != null) {
                  setState(() {
                    // Product ki copy banakar price update karein
                    Product updatedProduct = Product(
                      id: _cartItems[index]['product'].id,
                      name: _cartItems[index]['product'].name,
                      category: _cartItems[index]['product'].category,
                      purchasePrice: _cartItems[index]['product'].purchasePrice,
                      salePrice: newPrice,
                      stockQty: _cartItems[index]['product'].stockQty,
                    );
                    _cartItems[index]['product'] = updatedProduct;
                    _calculateTotal();
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    double received = double.tryParse(_receivedAmountController.text) ?? 0.0;
    
    // Agar Total minus mein hai (yani customer ko paise wapas dene hain)
    double returnAmount = 0.0;
    if (_grandTotal < 0) {
       returnAmount = _grandTotal.abs();
    } else if (received > _grandTotal) {
       returnAmount = received - _grandTotal;
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // 1. CUSTOMER DETAILS (Compact)
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
                      hintText: 'Phone',
                      prefixIcon: Icon(Icons.phone, size: 20),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 2. SEARCH & RETURN MODE ROW
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search product...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // RETURN BUTTON (Candela Style)
              SizedBox(
                height: 45,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isReturnMode = !_isReturnMode;
                    });
                  },
                  icon: Icon(_isReturnMode ? Icons.cancel : Icons.assignment_return),
                  label: Text(_isReturnMode ? 'RETURN ON' : 'RETURN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isReturnMode ? Colors.red : Colors.grey.shade300,
                    foregroundColor: _isReturnMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),

          // Search Dropdown
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
                      // Agar return mode nahi hai to stock check karein
                      if (!_isReturnMode && p.stockQty <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Out of stock!')),
                        );
                      } else {
                        _addProductToCart(p);
                      }
                    },
                  );
                },
              ),
            ),
          
          const SizedBox(height: 8),
          
          // 3. CART ITEMS LIST
          Expanded(
            child: _cartItems.isEmpty
                ? Center(
                    child: Text(
                      _isReturnMode ? 'RETURN MODE ON: Select product to return.' : 'No items in bill.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final p = item['product'] as Product;
                      final qty = item['qty'] as int;
                      final itemTotal = p.salePrice * qty;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          dense: true,
                          title: Text(p.name),
                          subtitle: Text('$qty x Rs ${p.salePrice} (Tap to edit price)'),
                          onTap: () => _editPrice(index), // Price edit function
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Rs $itemTotal',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16,
                                  color: itemTotal < 0 ? Colors.red : Colors.black,
                                ),
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
              color: _isReturnMode ? Colors.red.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _isReturnMode ? Colors.red : Colors.blue),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Net Amount:', style: TextStyle(fontSize: 16)),
                    Text(
                      'Rs ${_grandTotal.toStringAsFixed(0)}', 
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold, 
                        color: _grandTotal < 0 ? Colors.red : Colors.blue,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _receivedAmountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Received',
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
                        const SnackBar(content: Text('Invoice Save ka function next step hai!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isReturnMode ? Colors.red : Colors.blue,
                    ),
                    child: const Text('SAVE INVOICE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
