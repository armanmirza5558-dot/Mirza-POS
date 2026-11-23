import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/product.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _purchaseController = TextEditingController();
  final _saleController = TextEditingController();
  final _stockController = TextEditingController();

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      Product newProduct = Product(
        name: _nameController.text,
        category: _categoryController.text,
        purchasePrice: double.parse(_purchaseController.text),
        salePrice: double.parse(_saleController.text),
        stockQty: int.parse(_stockController.text),
      );

      await DBHelper.insertProduct(newProduct);
      
      if (mounted) {
        Navigator.pop(context, true); // Wapas jao aur list update karo
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Product')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name / Model', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _purchaseController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Purchase Price', border: OutlineInputBorder(), prefixText: 'Rs '),
                validator: (val) => val!.isEmpty ? 'Enter price' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _saleController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sale Price', border: OutlineInputBorder(), prefixText: 'Rs '),
                validator: (val) => val!.isEmpty ? 'Enter price' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Opening Stock Qty', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Enter qty' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Save Product', style: TextStyle(fontSize: 18)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
