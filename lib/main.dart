import 'dart:convert';
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
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomePage(),
    );
  }
}
class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _heldBillsCount = 0; 

  // YAHAN LIST THEEK KI HAI
  static const List<Widget> _pages = <Widget>[
    StockScreen(), // Index 0
    Center(child: Text('Ledger - Coming Soon')), // Index 1
    Center(child: Text('Expense - Coming Soon')), // Index 2
    Center(child: Text('Reports - Coming Soon')), // Index 3
  ];

  @override
  void initState() {
    super.initState();
    _updateHeldBillsCount();
  }

  void _updateHeldBillsCount() async {
    final db = await DBHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM held_bills');
    if (mounted) {
      setState(() {
        _heldBillsCount = result.first['count'] as int;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Candela Style POS'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add_check, size: 28),
            tooltip: 'Held Bills',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HeldBillsScreen()),
              );
              _updateHeldBillsCount(); 
            },
          ),
        ],
      ),
      // YAHAN INDEX - 1 KI TABDEELI HAI
      body: _selectedIndex == 0 
          ? BillingScreen(
              onBillHeld: _updateHeldBillsCount, 
              heldCount: _heldBillsCount,
            ) 
          : _pages[_selectedIndex - 1],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        onTap: (index) => setState(() => _selectedIndex = index),
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
          : _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        onTap: (index) => setState(() => _selectedIndex = index),
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
  final VoidCallback onBillHeld;
  final int heldCount;
  
  const BillingScreen({super.key, required this.onBillHeld, required this.heldCount});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _searchController = TextEditingController();
  final _receivedAmountController = TextEditingController();
  final _noteController = TextEditingController();
  final _billDiscountController = TextEditingController(); // Bill Discount ke liye

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Map<String, dynamic>> _cartItems = [];
  
  double _grandTotal = 0.0;
  bool _isReturnMode = false;
  String _paymentMode = 'Cash';

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(() => filterProducts(_searchController.text));
    
    // Jab bhi Received ya Bill Discount change ho, total update ho
    _receivedAmountController.addListener(() => setState(() {}));
    _billDiscountController.addListener(() => _calculateTotal());
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
        _filteredProducts = _allProducts.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList();
      });
    }
  }

  void _addProductToCart(Product product) {
    setState(() {
      int qtyToAdd = _isReturnMode ? -1 : 1;
      int index = _cartItems.indexWhere((item) => item['product'].id == product.id);
      if (index >= 0) {
        _cartItems[index]['qty'] += qtyToAdd;
        if (_cartItems[index]['qty'] == 0) _cartItems.removeAt(index);
      } else {
        _cartItems.add({'product': product, 'qty': qtyToAdd, 'discount': 0.0});
      }
      _calculateTotal();
      _searchController.clear();
      _filteredProducts = [];
    });
  }

  // Qty Plus Minus Functions
  void _increaseQty(int index) {
    setState(() {
      _cartItems[index]['qty'] += 1;
      _calculateTotal();
    });
  }

  void _decreaseQty(int index) {
    setState(() {
      if (_cartItems[index]['qty'] > 1) {
        _cartItems[index]['qty'] -= 1;
      } else {
        _cartItems.removeAt(index); // Agar 1 se kam ho to item delete
      }
      _calculateTotal();
    });
  }

  void _editPrice(int index) {
    TextEditingController priceController = TextEditingController(text: _cartItems[index]['product'].salePrice.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Price'),
        content: TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'New Price', prefixText: 'Rs ')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              double? newPrice = double.tryParse(priceController.text);
              if (newPrice != null) {
                setState(() {
                  Product p = _cartItems[index]['product'];
                  _cartItems[index]['product'] = Product(id: p.id, name: p.name, category: p.category, purchasePrice: p.purchasePrice, salePrice: newPrice, stockQty: p.stockQty);
                  _calculateTotal();
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editDiscount(int index) {
    TextEditingController discController = TextEditingController(text: _cartItems[index]['discount'].toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Item Discount (Rs)'),
        content: TextField(controller: discController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Discount Amount', prefixText: 'Rs ')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              double? disc = double.tryParse(discController.text);
              if (disc != null) {
                setState(() { _cartItems[index]['discount'] = disc; _calculateTotal(); });
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Total Calculate Karny ka Function (Bill Discount ke sath)
  void _calculateTotal() {
    double subTotal = 0;
    for (var item in _cartItems) {
      double itemTotal = (item['product'].salePrice * item['qty']) - (item['discount'] * item['qty']);
      subTotal += itemTotal;
    }
    
    // Bill Discount minus karein
    double billDisc = double.tryParse(_billDiscountController.text) ?? 0.0;
    setState(() => _grandTotal = subTotal - billDisc);
  }

  void _holdBill() async {
    if (_cartItems.isEmpty) return;
    final db = await DBHelper.database;
    String cartJson = jsonEncode(_cartItems.map((e) => {
      'product': (e['product'] as Product).toMap(),
      'qty': e['qty'],
      'discount': e['discount'],
      'note': _noteController.text,
      'bill_discount': _billDiscountController.text // Bill discount bhi save ho raha hai
    }).toList());

    await db.insert('held_bills', {
      'customer_name': _customerNameController.text,
      'customer_phone': _customerPhoneController.text,
      'cart_data': cartJson,
      'date': DateTime.now().toString(),
    });

    setState(() {
      _cartItems.clear();
      _customerNameController.clear();
      _customerPhoneController.clear();
      _grandTotal = 0;
      _receivedAmountController.clear();
      _noteController.clear();
      _billDiscountController.clear();
    });
    
    widget.onBillHeld(); 
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill Held Successfully!')));
  }

  @override
  Widget build(BuildContext context) {
    double received = double.tryParse(_receivedAmountController.text) ?? 0.0;
    double returnAmount = (_grandTotal < 0) ? _grandTotal.abs() : (received > _grandTotal ? received - _grandTotal : 0.0);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Customer Details
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(hintText: 'Customer Name', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _customerPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(hintText: 'Phone', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          
          // Search & Return
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(hintText: 'Search Product...', prefixIcon: Icon(Icons.search, size: 20), border: OutlineInputBorder(), contentPadding: EdgeInsets.zero),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: () => setState(() => _isReturnMode = !_isReturnMode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isReturnMode ? Colors.red : Colors.grey.shade300,
                    foregroundColor: _isReturnMode ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(_isReturnMode ? 'RETURN ON' : 'RETURN', style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),

          // Search Dropdown
          if (_filteredProducts.isNotEmpty && _searchController.text.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300)),
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
                      if (!_isReturnMode && p.stockQty <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Out of stock!')));
                      } else {
                        _addProductToCart(p);
                      }
                    },
                  );
                },
              ),
            ),
          
          const SizedBox(height: 6),
          
          // Table Headers
          Container(
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Rate', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Disc', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),

          // Cart Items List
          Expanded(
            child: _cartItems.isEmpty
                ? const Center(child: Text('No items added', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final p = item['product'] as Product;
                      final qty = item['qty'] as int;
                      final disc = item['discount'] as double;
                      final total = (p.salePrice - disc) * qty;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Text(p.name, style: const TextStyle(fontSize: 12))),
                              
                              // Editable Price
                              Expanded(flex: 2, child: InkWell(onTap: () => _editPrice(index), child: Text('${p.salePrice}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.blue, decoration: TextDecoration.underline)))),
                              
                              // QTY PLUS MINUS BUTTONS
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    InkWell(
                                      onTap: () => _decreaseQty(index),
                                      child: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text('$qty', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                    ),
                                    InkWell(
                                      onTap: () => _increaseQty(index),
                                      child: const Icon(Icons.add_circle, color: Colors.green, size: 20),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Editable Discount
                              Expanded(flex: 2, child: InkWell(onTap: () => _editDiscount(index), child: Text('$disc', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.blue, decoration: TextDecoration.underline)))),
                              
                              Expanded(flex: 2, child: Text('$total', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: total < 0 ? Colors.red : Colors.black))),
                              
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () { setState(() { _cartItems.removeAt(index); _calculateTotal(); }); },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Checkout Section
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isReturnMode ? Colors.red.shade50 : Colors.blue.shade50,
              border: Border.all(color: _isReturnMode ? Colors.red : Colors.blue),
            ),
            child: Column(
              children: [
                // NOTE BOX
                SizedBox(
                  height: 35,
                  child: TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      hintText: 'Add Note / Comment...',
                      prefixIcon: Icon(Icons.note_add, size: 16, color: Colors.blue),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 6),

                // Payment Mode
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(children: [Radio<String>(value: 'Cash', groupValue: _paymentMode, onChanged: (val) => setState(() => _paymentMode = val!)), const Text('Cash', style: TextStyle(fontSize: 12))]),
                    Row(children: [Radio<String>(value: 'Credit', groupValue: _paymentMode, onChanged: (val) => setState(() => _paymentMode = val!)), const Text('Credit (Udhaar)', style: TextStyle(fontSize: 12))]),
                  ],
                ),
                const Divider(height: 4),
                
                // BILL DISCOUNT ROW
                Row(
                  children: [
                    const Text('Bill Discount:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      height: 30,
                      child: TextField(
                        controller: _billDiscountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'Rs', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 4)),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Total & Received
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Net Total: Rs ${_grandTotal.toStringAsFixed(0)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _grandTotal < 0 ? Colors.red : Colors.blue)),
                          Text('Return: Rs $returnAmount', style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      height: 35,
                      child: TextField(
                        controller: _receivedAmountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'Received', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 4)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // HOLD & SAVE
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: _holdBill,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          child: Text('HOLD (${widget.heldCount})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: _cartItems.isEmpty ? null : () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice Save logic coming next!')));
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: _isReturnMode ? Colors.red : Colors.blue),
                          child: const Text('SAVE INVOICE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- HELD BILLS SCREEN ----------------
class HeldBillsScreen extends StatefulWidget {
  const HeldBillsScreen({super.key});

  @override
  State<HeldBillsScreen> createState() => _HeldBillsScreenState();
}

class _HeldBillsScreenState extends State<HeldBillsScreen> {
  List<Map<String, dynamic>> _heldBills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHeldBills();
  }

  void _loadHeldBills() async {
    final db = await DBHelper.database;
    final result = await db.query('held_bills', orderBy: 'id DESC');
    setState(() {
      _heldBills = result;
      _isLoading = false;
    });
  }

  void _resumeBill(Map<String, dynamic> bill) async {
    Navigator.pop(context, bill); 
    final db = await DBHelper.database;
    await db.delete('held_bills', where: 'id = ?', whereArgs: [bill['id']]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Held Bills / Receipts')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _heldBills.isEmpty
              ? const Center(child: Text('No held bills found.'))
              : ListView.builder(
                  itemCount: _heldBills.length,
                  itemBuilder: (context, index) {
                    final bill = _heldBills[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: const Icon(Icons.receipt, color: Colors.orange),
                        title: Text(bill['customer_name'].isEmpty ? 'Walk-in Customer' : bill['customer_name']),
                        subtitle: Text('Phone: ${bill['customer_phone']}\nDate: ${bill['date'].substring(0, 16)}'),
                        isThreeLine: true,
                        trailing: ElevatedButton(
                          onPressed: () => _resumeBill(bill),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          child: const Text('RESUME', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
