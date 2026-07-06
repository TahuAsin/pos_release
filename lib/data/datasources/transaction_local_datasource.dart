import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../models/transaction_model.dart';
import '../models/transaction_item_model.dart';

class TransactionLocalDatasource {
  final DatabaseHelper _db;


  TransactionLocalDatasource(this._db);

  String generateTransactionCode() {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'TRX-$dateStr-$timeStr';
  }

  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    final db = await _db.database;

    return await db.transaction((txn) async {
      // Insert transaction
      final txId = await txn.insert(
        DatabaseHelper.tableTransactions,
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert transaction items
      for (final item in transaction.items) {
        final itemMap = item.toMap()..['transaction_id'] = txId;
        await txn.insert(
          DatabaseHelper.tableTransactionItems,
          itemMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Decrease stock
        await txn.rawUpdate('''
          UPDATE ${DatabaseHelper.tableProducts}
          SET stock = stock - ?, updated_at = ?
          WHERE id = ?
        ''', [item.quantity, DateTime.now().toIso8601String(), item.productId]);
      }

      return transaction.copyWith(id: txId);
    });
  }

  Future<List<TransactionModel>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int? limit,
    int? offset,
  }) async {
    final conditions = <String>[];
    final args = <dynamic>[];

    if (startDate != null) {
      conditions.add('t.created_at >= ?');
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      conditions.add('t.created_at <= ?');
      args.add(endDate.toIso8601String());
    }

    if (status != null) {
      conditions.add('t.status = ?');
      args.add(status);
    }

    final where = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final limitStr = limit != null ? 'LIMIT $limit' : '';
    final offsetStr = offset != null ? 'OFFSET $offset' : '';

    final results = await _db.rawQuery('''
      SELECT t.*
      FROM ${DatabaseHelper.tableTransactions} t
      $where
      ORDER BY t.created_at DESC
      $limitStr $offsetStr
    ''', args);

    final transactions = results.map((map) => TransactionModel.fromMap(map)).toList();

    // Load items for each transaction
    final withItems = <TransactionModel>[];
    for (final tx in transactions) {
      final items = await getTransactionItems(tx.id!);
      withItems.add(tx.copyWith(items: items));
    }

    return withItems;
  }

  Future<TransactionModel?> getTransactionById(int id) async {
    final results = await _db.query(
      DatabaseHelper.tableTransactions,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    final tx = TransactionModel.fromMap(results.first);
    final items = await getTransactionItems(id);
    return tx.copyWith(items: items);
  }

  Future<List<TransactionItemModel>> getTransactionItems(int transactionId) async {
    final results = await _db.rawQuery('''
      SELECT ti.*, p.cost_price
      FROM ${DatabaseHelper.tableTransactionItems} ti
      LEFT JOIN ${DatabaseHelper.tableProducts} p ON ti.product_id = p.id
      WHERE ti.transaction_id = ?
    ''', [transactionId]);

    return results.map((map) => TransactionItemModel.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getDailySummary(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final results = await _db.rawQuery('''
      SELECT 
        COUNT(*) as total_transactions,
        COALESCE(SUM(total), 0) as total_revenue,
        COALESCE(SUM(subtotal), 0) as total_subtotal
      FROM ${DatabaseHelper.tableTransactions}
      WHERE created_at >= ? AND created_at <= ? AND status = 'completed'
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

    // Calculate profit
    final profitResults = await _db.rawQuery('''
      SELECT COALESCE(SUM((ti.product_price - p.cost_price) * ti.quantity), 0) as total_profit
      FROM ${DatabaseHelper.tableTransactionItems} ti
      LEFT JOIN ${DatabaseHelper.tableProducts} p ON ti.product_id = p.id
      LEFT JOIN ${DatabaseHelper.tableTransactions} t ON ti.transaction_id = t.id
      WHERE t.created_at >= ? AND t.created_at <= ? AND t.status = 'completed'
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

    final summary = results.first;
    final profit = profitResults.first['total_profit'] ?? 0.0;

    return {
      'total_transactions': summary['total_transactions'] ?? 0,
      'total_revenue': summary['total_revenue'] ?? 0.0,
      'total_profit': profit,
    };
  }

  Future<List<Map<String, dynamic>>> getWeeklySalesData() async {
    final results = await _db.rawQuery('''
      SELECT 
        DATE(created_at) as date,
        COALESCE(SUM(total), 0) as total_revenue,
        COUNT(*) as transaction_count
      FROM ${DatabaseHelper.tableTransactions}
      WHERE created_at >= datetime('now', '-6 days') AND status = 'completed'
      GROUP BY DATE(created_at)
      ORDER BY date ASC
    ''');

    return results;
  }

  Future<List<Map<String, dynamic>>> getMonthlySalesData(int year, int month) async {
    final results = await _db.rawQuery('''
      SELECT 
        DATE(created_at) as date,
        COALESCE(SUM(total), 0) as total_revenue,
        COUNT(*) as transaction_count
      FROM ${DatabaseHelper.tableTransactions}
      WHERE strftime('%Y', created_at) = ? AND strftime('%m', created_at) = ?
      AND status = 'completed'
      GROUP BY DATE(created_at)
      ORDER BY date ASC
    ''', [year.toString(), month.toString().padLeft(2, '0')]);

    return results;
  }

  Future<List<Map<String, dynamic>>> getTopProducts({int limit = 5}) async {
    final results = await _db.rawQuery('''
      SELECT 
        ti.product_name,
        SUM(ti.quantity) as total_qty,
        SUM(ti.subtotal) as total_revenue
      FROM ${DatabaseHelper.tableTransactionItems} ti
      LEFT JOIN ${DatabaseHelper.tableTransactions} t ON ti.transaction_id = t.id
      WHERE t.status = 'completed'
      GROUP BY ti.product_id, ti.product_name
      ORDER BY total_qty DESC
      LIMIT ?
    ''', [limit]);

    return results;
  }

  Future<Map<String, dynamic>> getPeriodSummary(DateTime start, DateTime end) async {
    final results = await _db.rawQuery('''
      SELECT 
        COUNT(*) as total_transactions,
        COALESCE(SUM(total), 0) as total_revenue
      FROM ${DatabaseHelper.tableTransactions}
      WHERE created_at >= ? AND created_at <= ? AND status = 'completed'
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final profitResults = await _db.rawQuery('''
      SELECT COALESCE(SUM((ti.product_price - p.cost_price) * ti.quantity), 0) as total_profit,
             COALESCE(SUM(p.cost_price * ti.quantity), 0) as total_cost
      FROM ${DatabaseHelper.tableTransactionItems} ti
      LEFT JOIN ${DatabaseHelper.tableProducts} p ON ti.product_id = p.id
      LEFT JOIN ${DatabaseHelper.tableTransactions} t ON ti.transaction_id = t.id
      WHERE t.created_at >= ? AND t.created_at <= ? AND t.status = 'completed'
    ''', [start.toIso8601String(), end.toIso8601String()]);

    return {
      ...results.first,
      ...profitResults.first,
    };
  }
}
