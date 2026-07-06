import 'transaction_item_model.dart';

class TransactionModel {
  final int? id;
  final String transactionCode;
  final int? userId;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod;
  final double amountPaid;
  final double changeAmount;
  final String status;
  final String? notes;
  final List<TransactionItemModel> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionModel({
    this.id,
    required this.transactionCode,
    this.userId,
    required this.subtotal,
    this.discount = 0,
    this.tax = 0,
    required this.total,
    this.paymentMethod = 'cash',
    required this.amountPaid,
    this.changeAmount = 0,
    this.status = 'completed',
    this.notes,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      transactionCode: map['transaction_code'] as String,
      userId: map['user_id'] as int?,
      subtotal: (map['subtotal'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String? ?? 'cash',
      amountPaid: (map['amount_paid'] as num).toDouble(),
      changeAmount: (map['change_amount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'completed',
      notes: map['notes'] as String?,
      items: const [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'transaction_code': transactionCode,
      'user_id': userId,
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'payment_method': paymentMethod,
      'amount_paid': amountPaid,
      'change_amount': changeAmount,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    int? id,
    String? transactionCode,
    int? userId,
    double? subtotal,
    double? discount,
    double? tax,
    double? total,
    String? paymentMethod,
    double? amountPaid,
    double? changeAmount,
    String? status,
    String? notes,
    List<TransactionItemModel>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      transactionCode: transactionCode ?? this.transactionCode,
      userId: userId ?? this.userId,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountPaid: amountPaid ?? this.amountPaid,
      changeAmount: changeAmount ?? this.changeAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  double get netProfit => items.fold(0.0, (sum, item) => sum + item.profit);
}
