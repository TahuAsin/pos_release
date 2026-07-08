import 'dart:convert';

class CashRegisterSession {
  final int? id;
  final int userId;
  final double openingAmount;
  final double? closingAmount;
  final double? expectedAmount;
  final double totalSales;
  final int totalTransactions;
  final double totalCashSales;
  final double totalQrisSales;
  final double? difference;
  final String status;
  final DateTime openedAt;
  final DateTime? closedAt;
  final String? notes;

  const CashRegisterSession({
    this.id,
    required this.userId,
    required this.openingAmount,
    this.closingAmount,
    this.expectedAmount,
    this.totalSales = 0,
    this.totalTransactions = 0,
    this.totalCashSales = 0,
    this.totalQrisSales = 0,
    this.difference,
    this.status = 'open',
    required this.openedAt,
    this.closedAt,
    this.notes,
  });

  bool get isOpen => status == 'open';
  
  double get calculatedExpectedAmount => openingAmount + totalCashSales;
  
  double get calculatedDifference => (closingAmount ?? 0) - calculatedExpectedAmount;

  CashRegisterSession copyWith({
    int? id,
    int? userId,
    double? openingAmount,
    double? closingAmount,
    double? expectedAmount,
    double? totalSales,
    int? totalTransactions,
    double? totalCashSales,
    double? totalQrisSales,
    double? difference,
    String? status,
    DateTime? openedAt,
    DateTime? closedAt,
    String? notes,
  }) {
    return CashRegisterSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      openingAmount: openingAmount ?? this.openingAmount,
      closingAmount: closingAmount ?? this.closingAmount,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      totalSales: totalSales ?? this.totalSales,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      totalCashSales: totalCashSales ?? this.totalCashSales,
      totalQrisSales: totalQrisSales ?? this.totalQrisSales,
      difference: difference ?? this.difference,
      status: status ?? this.status,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'opening_amount': openingAmount,
      'closing_amount': closingAmount,
      'expected_amount': expectedAmount,
      'total_sales': totalSales,
      'total_transactions': totalTransactions,
      'total_cash_sales': totalCashSales,
      'total_qris_sales': totalQrisSales,
      'difference': difference,
      'status': status,
      'opened_at': openedAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory CashRegisterSession.fromMap(Map<String, dynamic> map) {
    return CashRegisterSession(
      id: map['id']?.toInt(),
      userId: map['user_id']?.toInt() ?? 0,
      openingAmount: map['opening_amount']?.toDouble() ?? 0.0,
      closingAmount: map['closing_amount']?.toDouble(),
      expectedAmount: map['expected_amount']?.toDouble(),
      totalSales: map['total_sales']?.toDouble() ?? 0.0,
      totalTransactions: map['total_transactions']?.toInt() ?? 0,
      totalCashSales: map['total_cash_sales']?.toDouble() ?? 0.0,
      totalQrisSales: map['total_qris_sales']?.toDouble() ?? 0.0,
      difference: map['difference']?.toDouble(),
      status: map['status'] ?? 'open',
      openedAt: DateTime.parse(map['opened_at']),
      closedAt: map['closed_at'] != null ? DateTime.parse(map['closed_at']) : null,
      notes: map['notes'],
    );
  }

  String toJson() => json.encode(toMap());

  factory CashRegisterSession.fromJson(String source) => CashRegisterSession.fromMap(json.decode(source));
}
