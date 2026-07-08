import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../models/cash_register_model.dart';

class CashRegisterDatasource {
  final DatabaseHelper _db;

  CashRegisterDatasource(this._db);

  Future<CashRegisterSession> openSession(int userId, double openingAmount) async {
    final db = await _db.database;
    final now = DateTime.now();
    
    final session = CashRegisterSession(
      userId: userId,
      openingAmount: openingAmount,
      openedAt: now,
      status: 'open',
    );

    final id = await db.insert(
      DatabaseHelper.tableCashRegisterSessions,
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return session.copyWith(id: id);
  }

  Future<CashRegisterSession?> getActiveSession(int userId) async {
    final db = await _db.database;
    final results = await db.query(
      DatabaseHelper.tableCashRegisterSessions,
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'open'],
      orderBy: 'opened_at DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return CashRegisterSession.fromMap(results.first);
  }

  Future<void> updateSessionTotals(int sessionId) async {
    final db = await _db.database;
    
    // Get the session first to know its start time
    final sessionResults = await db.query(
      DatabaseHelper.tableCashRegisterSessions,
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    
    if (sessionResults.isEmpty) return;
    final session = CashRegisterSession.fromMap(sessionResults.first);
    
    // We get all transactions that occurred since openedAt (assuming user only has one active session)
    // To be perfectly accurate, we should ideally link transactions to session_id, but since we didn't add session_id to transactions table, 
    // we calculate based on time window: from openedAt to now (if open) or closedAt.
    
    final endTime = session.closedAt ?? DateTime.now();
    
    final txResults = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_tx,
        COALESCE(SUM(total), 0) as total_sales,
        COALESCE(SUM(CASE WHEN payment_method = 'cash' THEN total ELSE 0 END), 0) as cash_sales,
        COALESCE(SUM(CASE WHEN payment_method = 'qris' THEN total ELSE 0 END), 0) as qris_sales
      FROM ${DatabaseHelper.tableTransactions}
      WHERE user_id = ? AND created_at >= ? AND created_at <= ? AND status = 'completed'
    ''', [session.userId, session.openedAt.toIso8601String(), endTime.toIso8601String()]);
    
    final data = txResults.first;
    
    final totalTx = (data['total_tx'] as num?)?.toInt() ?? 0;
    final totalSales = (data['total_sales'] as num?)?.toDouble() ?? 0.0;
    final cashSales = (data['cash_sales'] as num?)?.toDouble() ?? 0.0;
    final qrisSales = (data['qris_sales'] as num?)?.toDouble() ?? 0.0;
    
    await db.update(
      DatabaseHelper.tableCashRegisterSessions,
      {
        'total_transactions': totalTx,
        'total_sales': totalSales,
        'total_cash_sales': cashSales,
        'total_qris_sales': qrisSales,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<CashRegisterSession> closeSession(int sessionId, double closingAmount, String? notes) async {
    final db = await _db.database;
    
    // First make sure totals are up to date
    await updateSessionTotals(sessionId);
    
    // Re-fetch to calculate difference
    final results = await db.query(
      DatabaseHelper.tableCashRegisterSessions,
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    
    final session = CashRegisterSession.fromMap(results.first);
    final expected = session.calculatedExpectedAmount;
    final difference = closingAmount - expected;
    final now = DateTime.now();
    
    await db.update(
      DatabaseHelper.tableCashRegisterSessions,
      {
        'closing_amount': closingAmount,
        'expected_amount': expected,
        'difference': difference,
        'notes': notes,
        'status': 'closed',
        'closed_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    
    return session.copyWith(
      closingAmount: closingAmount,
      expectedAmount: expected,
      difference: difference,
      notes: notes,
      status: 'closed',
      closedAt: now,
    );
  }
}
