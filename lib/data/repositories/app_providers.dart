import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/database_helper.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/product_local_datasource.dart';
import '../../data/datasources/transaction_local_datasource.dart';
import '../../data/models/user_model.dart';

// Core providers
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// Datasource providers
final authDatasourceProvider = Provider<AuthLocalDatasource>((ref) {
  return AuthLocalDatasource(ref.watch(databaseHelperProvider));
});

final productDatasourceProvider = Provider<ProductLocalDatasource>((ref) {
  return ProductLocalDatasource(ref.watch(databaseHelperProvider));
});

final transactionDatasourceProvider = Provider<TransactionLocalDatasource>((ref) {
  return TransactionLocalDatasource(ref.watch(databaseHelperProvider));
});

// Auth state
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthLocalDatasource _datasource;
  SharedPreferences? _prefs;

  AuthNotifier(this._datasource) : super(const AuthState()) {
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    _prefs = await SharedPreferences.getInstance();
    final savedUserId = _prefs?.getInt('user_id');
    if (savedUserId != null) {
      final user = await _datasource.getUserById(savedUserId);
      if (user != null) {
        state = state.copyWith(user: user);
      }
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _datasource.login(username, password);
      if (user != null) {
        await _prefs?.setInt('user_id', user.id!);
        state = state.copyWith(user: user, isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Username atau password salah',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Terjadi kesalahan: $e',
      );
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String password,
    required String fullName,
    String? businessName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final isTaken = await _datasource.isUsernameTaken(username);
      if (isTaken) {
        state = state.copyWith(
          isLoading: false,
          error: 'Username sudah digunakan',
        );
        return false;
      }

      final now = DateTime.now();
      final user = UserModel(
        username: username,
        password: password,
        fullName: fullName,
        businessName: businessName,
        createdAt: now,
        updatedAt: now,
      );

      final id = await _datasource.register(user);
      final newUser = user.copyWith(id: id);
      await _prefs?.setInt('user_id', id);
      state = state.copyWith(user: newUser, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Terjadi kesalahan: $e',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _prefs?.remove('user_id');
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authDatasourceProvider));
});

// Theme state
class ThemeNotifier extends StateNotifier<bool> {
  SharedPreferences? _prefs;

  ThemeNotifier() : super(false) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    state = _prefs?.getBool('is_dark_mode') ?? false;
  }

  Future<void> toggleTheme() async {
    state = !state;
    await _prefs?.setBool('is_dark_mode', state);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
});
