import '../../core/database/database_helper.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

class ProductLocalDatasource {
  final DatabaseHelper _db;

  ProductLocalDatasource(this._db);

  Future<List<ProductModel>> getProducts({
    String? searchQuery,
    int? categoryId,
    bool? isActive,
  }) async {
    final conditions = <String>[];
    final args = <dynamic>[];

    if (isActive != null) {
      conditions.add('p.is_active = ?');
      args.add(isActive ? 1 : 0);
    }

    if (categoryId != null) {
      conditions.add('p.category_id = ?');
      args.add(categoryId);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      conditions.add('p.name LIKE ?');
      args.add('%$searchQuery%');
    }

    final where = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    final results = await _db.rawQuery('''
      SELECT p.*, c.name as category_name
      FROM ${DatabaseHelper.tableProducts} p
      LEFT JOIN ${DatabaseHelper.tableCategories} c ON p.category_id = c.id
      $where
      ORDER BY p.name ASC
    ''', args);

    return results.map((map) => ProductModel.fromMap(map)).toList();
  }

  Future<ProductModel?> getProductById(int id) async {
    final results = await _db.rawQuery('''
      SELECT p.*, c.name as category_name
      FROM ${DatabaseHelper.tableProducts} p
      LEFT JOIN ${DatabaseHelper.tableCategories} c ON p.category_id = c.id
      WHERE p.id = ?
      LIMIT 1
    ''', [id]);

    if (results.isEmpty) return null;
    return ProductModel.fromMap(results.first);
  }

  Future<List<ProductModel>> getLowStockProducts() async {
    final results = await _db.rawQuery('''
      SELECT p.*, c.name as category_name
      FROM ${DatabaseHelper.tableProducts} p
      LEFT JOIN ${DatabaseHelper.tableCategories} c ON p.category_id = c.id
      WHERE p.stock <= p.min_stock AND p.is_active = 1
      ORDER BY p.stock ASC
    ''');

    return results.map((map) => ProductModel.fromMap(map)).toList();
  }

  Future<int> insertProduct(ProductModel product) async {
    return await _db.insert(DatabaseHelper.tableProducts, product.toMap());
  }

  Future<int> updateProduct(ProductModel product) async {
    return await _db.update(
      DatabaseHelper.tableProducts,
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> updateStock(int productId, int newStock) async {
    final now = DateTime.now().toIso8601String();
    return await _db.update(
      DatabaseHelper.tableProducts,
      {'stock': newStock, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<int> decreaseStock(int productId, int quantity) async {
    final db = await _db.database;
    return await db.rawUpdate('''
      UPDATE ${DatabaseHelper.tableProducts}
      SET stock = stock - ?, updated_at = ?
      WHERE id = ? AND stock >= ?
    ''', [quantity, DateTime.now().toIso8601String(), productId, quantity]);
  }

  Future<int> deleteProduct(int id) async {
    return await _db.update(
      DatabaseHelper.tableProducts,
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<CategoryModel>> getCategories() async {
    final results = await _db.query(
      DatabaseHelper.tableCategories,
      orderBy: 'name ASC',
    );
    return results.map((map) => CategoryModel.fromMap(map)).toList();
  }

  Future<int> insertCategory(CategoryModel category) async {
    return await _db.insert(DatabaseHelper.tableCategories, category.toMap());
  }

  Future<void> deleteCategory(int id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update(
        DatabaseHelper.tableProducts,
        {'category_id': null},
        where: 'category_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        DatabaseHelper.tableCategories,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<int> getProductsCount() async {
    final results = await _db.rawQuery('''
      SELECT COUNT(*) as count FROM ${DatabaseHelper.tableProducts}
      WHERE is_active = 1
    ''');
    return (results.first['count'] as int?) ?? 0;
  }
}
