import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/repositories/app_providers.dart';
import '../../../presentation/widgets/app_button.dart';
import '../../../presentation/widgets/app_text_field.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import 'register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () => _slideController.forward());
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('saved_username');
    final savedPassword = prefs.getString('saved_password');
    if (savedUsername != null && savedPassword != null) {
      if (mounted) {
        setState(() {
          _usernameController.text = savedUsername;
          _passwordController.text = savedPassword;
          _rememberMe = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    final success = await ref.read(authProvider.notifier).login(
      username,
      password,
    );

    if (success && mounted) {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('saved_username', username);
        await prefs.setString('saved_password', password);
      } else {
        await prefs.remove('saved_username');
        await prefs.remove('saved_password');
      }
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainShell(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            height: size.height * 0.45,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      child: Column(
                        children: [
                          const SizedBox(height: AppSizes.lg),
                          // Logo
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Icon(Icons.point_of_sale_rounded, size: 50, color: AppColors.primary),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSizes.md),
                          const Text(
                            AppStrings.appName,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.appTagline,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: AppSizes.xl),
                        ],
                      ),
                    ),
                  ),

                  // Form card
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.lg),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.loginTitle,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppStrings.loginSubtitle,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: AppSizes.lg),

                                AppTextField(
                                  label: AppStrings.username,
                                  hint: 'Masukkan username',
                                  controller: _usernameController,
                                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                                  validator: (v) => v?.isEmpty == true ? 'Username wajib diisi' : null,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: AppSizes.md),

                                AppTextField(
                                  label: AppStrings.password,
                                  hint: 'Masukkan password',
                                  controller: _passwordController,
                                  obscureText: true,
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                  validator: (v) => v?.isEmpty == true ? 'Password wajib diisi' : null,
                                  textInputAction: TextInputAction.done,
                                ),
                                const SizedBox(height: AppSizes.sm),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _rememberMe,
                                      onChanged: (v) {
                                        setState(() => _rememberMe = v ?? false);
                                      },
                                      activeColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    ),
                                    const Text('Ingat saya', style: TextStyle(fontSize: 14)),
                                  ],
                                ),

                                if (authState.error != null) ...[
                                  const SizedBox(height: AppSizes.md),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            authState.error!,
                                            style: const TextStyle(color: AppColors.error, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: AppSizes.lg),

                                GradientButton(
                                  label: AppStrings.login,
                                  onPressed: _handleLogin,
                                  isLoading: authState.isLoading,
                                ),

                                const SizedBox(height: AppSizes.md),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      AppStrings.noAccount,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                        );
                                      },
                                      child: const Text(
                                        AppStrings.register,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSizes.sm),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
