import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/database_helper.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/product_local_datasource.dart';
import '../../data/datasources/transaction_local_datasource.dart';
import '../../data/datasources/cash_register_datasource.dart';
import '../../data/datasources/expense_local_datasource.dart';
import '../../data/models/user_model.dart';
import '../../data/models/cash_register_model.dart';

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

final expenseDatasourceProvider = Provider<ExpenseLocalDatasource>((ref) {
  return ExpenseLocalDatasource();
});

final productDatasourceProvider = Provider<ProductLocalDatasource>((ref) {
  return ProductLocalDatasource(ref.watch(databaseHelperProvider));
});

final transactionDatasourceProvider = Provider<TransactionLocalDatasource>((ref) {
  return TransactionLocalDatasource(ref.watch(databaseHelperProvider));
});

final cashRegisterDatasourceProvider = Provider<CashRegisterDatasource>((ref) {
  return CashRegisterDatasource(ref.watch(databaseHelperProvider));
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

  Future<bool> updateUser({
    required String fullName,
    String? businessName,
    required String username,
    String? password,
  }) async {
    final currentUser = state.user;
    if (currentUser == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      if (username != currentUser.username) {
        final isTaken = await _datasource.isUsernameTaken(username);
        if (isTaken) {
          state = state.copyWith(
            isLoading: false,
            error: 'Username sudah digunakan',
          );
          return false;
        }
      }

      final updatedUser = currentUser.copyWith(
        fullName: fullName,
        businessName: businessName,
        username: username,
        password: (password != null && password.isNotEmpty) ? password : currentUser.password,
        updatedAt: DateTime.now(),
      );

      await _datasource.updateUser(updatedUser);
      state = state.copyWith(user: updatedUser, isLoading: false);
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

// Cash Register State
class CashRegisterState {
  final CashRegisterSession? session;
  final bool isLoading;

  const CashRegisterState({this.session, this.isLoading = false});

  CashRegisterState copyWith({
    CashRegisterSession? session,
    bool? isLoading,
    bool clearSession = false,
  }) {
    return CashRegisterState(
      session: clearSession ? null : (session ?? this.session),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isOpen => session != null && session!.isOpen;
}

class CashRegisterNotifier extends StateNotifier<CashRegisterState> {
  final CashRegisterDatasource _datasource;
  SharedPreferences? _prefs;

  CashRegisterNotifier(this._datasource) : super(const CashRegisterState()) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await checkSession();
  }

  Future<void> checkSession() async {
    final userId = _prefs?.getInt('user_id');
    if (userId != null) {
      final session = await _datasource.getActiveSession(userId);
      state = state.copyWith(session: session, clearSession: session == null);
    }
  }

  Future<void> openRegister(double amount) async {
    final userId = _prefs?.getInt('user_id');
    if (userId == null) return;
    
    state = state.copyWith(isLoading: true);
    final session = await _datasource.openSession(userId, amount);
    state = state.copyWith(session: session, isLoading: false);
  }

  Future<void> closeRegister(double closingAmount, String? notes) async {
    final sessionId = state.session?.id;
    if (sessionId == null) return;

    state = state.copyWith(isLoading: true);
    await _datasource.closeSession(sessionId, closingAmount, notes);
    state = state.copyWith(clearSession: true, isLoading: false);
  }
  
  Future<void> updateTotals() async {
    final sessionId = state.session?.id;
    if (sessionId != null) {
      await _datasource.updateSessionTotals(sessionId);
      await checkSession(); // reload updated session
    }
  }
}

final cashRegisterProvider = StateNotifierProvider<CashRegisterNotifier, CashRegisterState>((ref) {
  return CashRegisterNotifier(ref.watch(cashRegisterDatasourceProvider));
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
