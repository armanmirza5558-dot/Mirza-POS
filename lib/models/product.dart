class Product {
  int? id;
  String name;
  String category;
  double purchasePrice;
  double salePrice;
  int stockQty;
  int lowStockThreshold;

  Product({
    this.id,
    required this.name,
    required this.category,
    required this.purchasePrice,
    required this.salePrice,
    required this.stockQty,
    this.lowStockThreshold = 5,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'stock_qty': stockQty,
      'low_stock_threshold': lowStockThreshold,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      purchasePrice: map['purchase_price'],
      salePrice: map['sale_price'],
      stockQty: map['stock_qty'],
      lowStockThreshold: map['low_stock_threshold'],
    );
  }
}
