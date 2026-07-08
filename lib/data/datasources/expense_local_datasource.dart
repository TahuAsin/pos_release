import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../models/expense_model.dart';

class ExpenseLocalDatasource {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<Database> get _db async {
    final database = await _databaseHelper.database;
    // Failsafe for development (Hot Reload/Restart): ensure table exists
    await database.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseHelper.tableExpenses} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        expense_date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    return database;
  }

  Future<int> insertExpense(ExpenseModel expense) async {
    final db = await _db;
    return await db.insert(
      DatabaseHelper.tableExpenses,
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExpenseModel>> getExpenses({DateTime? startDate, DateTime? endDate}) async {
    final db = await _db;
    List<Map<String, dynamic>> maps;

    if (startDate != null && endDate != null) {
      maps = await db.query(
        DatabaseHelper.tableExpenses,
        where: 'expense_date >= ? AND expense_date <= ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'expense_date DESC',
      );
    } else {
      maps = await db.query(
        DatabaseHelper.tableExpenses,
        orderBy: 'expense_date DESC',
      );
    }

    return maps.map((e) => ExpenseModel.fromMap(e)).toList();
  }

  Future<int> updateExpense(ExpenseModel expense) async {
    if (expense.id == null) return 0;
    final db = await _db;
    return await db.update(
      DatabaseHelper.tableExpenses,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await _db;
    return await db.delete(
      DatabaseHelper.tableExpenses,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalExpenses(DateTime start, DateTime end) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total 
      FROM ${DatabaseHelper.tableExpenses} 
      WHERE expense_date >= ? AND expense_date <= ?
    ''', [start.toIso8601String(), end.toIso8601String()]);
    
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
