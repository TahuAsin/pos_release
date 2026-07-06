import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/repositories/app_providers.dart';
import '../../../presentation/widgets/app_button.dart';
import '../../../presentation/widgets/app_text_field.dart';
import '../../dashboard/presentation/dashboard_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await ref.read(authProvider.notifier).register(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      businessName: _businessNameController.text.trim().isEmpty
          ? null
          : _businessNameController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _businessNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        AppStrings.registerTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
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
                                AppStrings.registerSubtitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: AppSizes.lg),

                              AppTextField(
                                label: AppStrings.fullName,
                                hint: 'Nama lengkap Anda',
                                controller: _fullNameController,
                                prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                                validator: (v) => v?.isEmpty == true ? 'Nama lengkap wajib diisi' : null,
                              ),
                              const SizedBox(height: AppSizes.md),

                              AppTextField(
                                label: AppStrings.businessName,
                                hint: 'Nama usaha/toko (opsional)',
                                controller: _businessNameController,
                                prefixIcon: const Icon(Icons.store_outlined, size: 20),
                              ),
                              const SizedBox(height: AppSizes.md),

                              AppTextField(
                                label: AppStrings.username,
                                hint: 'Buat username unik',
                                controller: _usernameController,
                                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                                validator: (v) {
                                  if (v?.isEmpty == true) return 'Username wajib diisi';
                                  if (v!.length < 4) return 'Username minimal 4 karakter';
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSizes.md),

                              AppTextField(
                                label: AppStrings.password,
                                hint: 'Buat password kuat',
                                controller: _passwordController,
                                obscureText: true,
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                validator: (v) {
                                  if (v?.isEmpty == true) return 'Password wajib diisi';
                                  if (v!.length < 6) return 'Password minimal 6 karakter';
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSizes.md),

                              AppTextField(
                                label: AppStrings.confirmPassword,
                                hint: 'Ulangi password',
                                controller: _confirmPasswordController,
                                obscureText: true,
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                textInputAction: TextInputAction.done,
                                validator: (v) {
                                  if (v?.isEmpty == true) return 'Konfirmasi password wajib diisi';
                                  if (v != _passwordController.text) return 'Password tidak cocok';
                                  return null;
                                },
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
                                label: AppStrings.register,
                                onPressed: _handleRegister,
                                isLoading: authState.isLoading,
                              ),

                              const SizedBox(height: AppSizes.md),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    AppStrings.hasAccount,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: const Text(
                                      AppStrings.login,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
