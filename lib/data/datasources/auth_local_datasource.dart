import '../../core/database/database_helper.dart';
import '../models/user_model.dart';

class AuthLocalDatasource {
  final DatabaseHelper _db;

  AuthLocalDatasource(this._db);

  Future<UserModel?> login(String username, String password) async {
    final results = await _db.query(
      DatabaseHelper.tableUsers,
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  Future<UserModel?> getUserByUsername(String username) async {
    final results = await _db.query(
      DatabaseHelper.tableUsers,
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  Future<bool> isUsernameTaken(String username) async {
    final results = await _db.query(
      DatabaseHelper.tableUsers,
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  Future<int> register(UserModel user) async {
    return await _db.insert(DatabaseHelper.tableUsers, user.toMap());
  }

  Future<int> updateUser(UserModel user) async {
    return await _db.update(
      DatabaseHelper.tableUsers,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<UserModel?> getUserById(int id) async {
    final results = await _db.query(
      DatabaseHelper.tableUsers,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }
}
