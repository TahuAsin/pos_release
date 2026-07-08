class ProductModel {
  final int? id;
  final String name;
  final String? description;
  final String? barcode;
  final double price;
  final double costPrice;
  final int stock;
  final int? categoryId;
  final String? categoryName;
  final String? imagePath;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    this.id,
    required this.name,
    this.description,
    this.barcode,
    required this.price,
    this.costPrice = 0,
    this.stock = 0,
    this.categoryId,
    this.categoryName,
    this.imagePath,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      barcode: map['barcode'] as String?,
      price: (map['price'] as num).toDouble(),
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0.0,
      stock: map['stock'] as int? ?? 0,
      categoryId: map['category_id'] as int?,
      categoryName: map['category_name'] as String?,
      imagePath: map['image_path'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'barcode': barcode,
      'price': price,
      'cost_price': costPrice,
      'stock': stock,
      'category_id': categoryId,
      'image_path': imagePath,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProductModel copyWith({
    int? id,
    String? name,
    String? description,
    String? barcode,
    double? price,
    double? costPrice,
    int? stock,
    int? categoryId,
    String? categoryName,
    String? imagePath,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      imagePath: imagePath ?? this.imagePath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isLowStock => stock <= 10;
  bool get isOutOfStock => stock <= 0;
  double get profit => price - costPrice;
  double get profitMargin => costPrice > 0 ? (profit / costPrice) * 100 : 0;
}
