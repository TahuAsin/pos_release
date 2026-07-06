import 'package:alflow_pos/data/models/product_model.dart';

class TransactionItemModel {
  final int? id;
  final int? transactionId;
  final int productId;
  final String productName;
  final double productPrice;
  final double costPrice;
  final int quantity;
  final double discount;
  final double subtotal;
  final DateTime createdAt;

  // For UI only (not stored in DB)
  final ProductModel? product;

  const TransactionItemModel({
    this.id,
    this.transactionId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    this.costPrice = 0,
    required this.quantity,
    this.discount = 0,
    required this.subtotal,
    required this.createdAt,
    this.product,
  });

  factory TransactionItemModel.fromMap(Map<String, dynamic> map) {
    return TransactionItemModel(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as int?,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      productPrice: (map['product_price'] as num).toDouble(),
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] as int,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory TransactionItemModel.fromProduct(ProductModel product, int qty) {
    return TransactionItemModel(
      productId: product.id!,
      productName: product.name,
      productPrice: product.price,
      costPrice: product.costPrice,
      quantity: qty,
      subtotal: product.price * qty,
      createdAt: DateTime.now(),
      product: product,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      'product_id': productId,
      'product_name': productName,
      'product_price': productPrice,
      'quantity': quantity,
      'discount': discount,
      'subtotal': subtotal,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TransactionItemModel copyWith({
    int? id,
    int? transactionId,
    int? productId,
    String? productName,
    double? productPrice,
    double? costPrice,
    int? quantity,
    double? discount,
    double? subtotal,
    DateTime? createdAt,
    ProductModel? product,
  }) {
    return TransactionItemModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
      subtotal: subtotal ?? this.subtotal,
      createdAt: createdAt ?? this.createdAt,
      product: product ?? this.product,
    );
  }

  double get profit => (productPrice - costPrice) * quantity;
  double get unitProfit => productPrice - costPrice;
}
