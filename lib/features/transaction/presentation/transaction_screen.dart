import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/transaction_item_model.dart';
import '../../../data/repositories/app_providers.dart';
import '../../../presentation/widgets/app_button.dart';
import '../../../presentation/widgets/app_text_field.dart';
import '../../../presentation/widgets/shimmer_loading.dart';
import '../../../presentation/widgets/empty_state.dart';
import '../../dashboard/presentation/dashboard_screen.dart';

// Cart state
class CartState {
  final List<TransactionItemModel> items;
  final double discount;
  final String paymentMethod;

  const CartState({
    this.items = const [],
    this.discount = 0,
    this.paymentMethod = 'cash',
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get total => subtotal - discount;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    List<TransactionItemModel>? items,
    double? discount,
    String? paymentMethod,
  }) {
    return CartState(
      items: items ?? this.items,
      discount: discount ?? this.discount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addProduct(ProductModel product) {
    final existingIdx = state.items.indexWhere((item) => item.productId == product.id);

    if (existingIdx >= 0) {
      final existing = state.items[existingIdx];
      if (existing.quantity >= product.stock) return; // Max stock limit

      final updatedItems = [...state.items];
      updatedItems[existingIdx] = existing.copyWith(
        quantity: existing.quantity + 1,
        subtotal: existing.productPrice * (existing.quantity + 1),
      );
      state = state.copyWith(items: updatedItems);
    } else {
      if (product.stock <= 0) return;
      state = state.copyWith(
        items: [...state.items, TransactionItemModel.fromProduct(product, 1)],
      );
    }
  }

  void removeProduct(int productId) {
    final existingIdx = state.items.indexWhere((item) => item.productId == productId);
    if (existingIdx < 0) return;

    final existing = state.items[existingIdx];
    if (existing.quantity <= 1) {
      final updatedItems = state.items.where((item) => item.productId != productId).toList();
      state = state.copyWith(items: updatedItems);
    } else {
      final updatedItems = [...state.items];
      updatedItems[existingIdx] = existing.copyWith(
        quantity: existing.quantity - 1,
        subtotal: existing.productPrice * (existing.quantity - 1),
      );
      state = state.copyWith(items: updatedItems);
    }
  }

  void setQuantity(int productId, int qty) {
    if (qty <= 0) {
      final updatedItems = state.items.where((item) => item.productId != productId).toList();
      state = state.copyWith(items: updatedItems);
      return;
    }

    final existingIdx = state.items.indexWhere((item) => item.productId == productId);
    if (existingIdx < 0) return;

    final existing = state.items[existingIdx];
    final updatedItems = [...state.items];
    updatedItems[existingIdx] = existing.copyWith(
      quantity: qty,
      subtotal: existing.productPrice * qty,
    );
    state = state.copyWith(items: updatedItems);
  }

  void removeItem(int productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.productId != productId).toList(),
    );
  }

  void setDiscount(double discount) {
    state = state.copyWith(discount: discount);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void clearCart() {
    state = const CartState();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

// Products for kasir
final kasirProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final datasource = ref.watch(productDatasourceProvider);
  final search = ref.watch(kasirSearchProvider);
  final categoryId = ref.watch(kasirCategoryProvider);
  return await datasource.getProducts(
    searchQuery: search.isEmpty ? null : search,
    categoryId: categoryId,
    isActive: true,
  );
});

final kasirSearchProvider = StateProvider<String>((ref) => '');
final kasirCategoryProvider = StateProvider<int?>((ref) => null);
final kasirCategoriesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final datasource = ref.watch(productDatasourceProvider);
  return await datasource.getCategories();
});

class TransactionScreen extends ConsumerStatefulWidget {
  const TransactionScreen({super.key});

  @override
  ConsumerState<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends ConsumerState<TransactionScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Kasir'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final cart = ref.watch(cartProvider);
              return cart.items.isNotEmpty
                  ? TextButton.icon(
                      onPressed: () => _clearCartConfirm(context),
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
                      label: const Text('Hapus', style: TextStyle(color: Colors.white, fontSize: 13)),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: isTablet
          ? _buildTabletLayout(context, isDark)
          : _buildPhoneLayout(context, isDark),
    );
  }

  Widget _buildTabletLayout(BuildContext context, bool isDark) {
    return Row(
      children: [
        // Product grid (left)
        Expanded(
          flex: 6,
          child: _buildProductSection(context, isDark),
        ),
        // Cart (right)
        Container(
          width: AppSizes.sidebarWidth,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            border: Border(
              left: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
          ),
          child: _buildCartSection(context, isDark),
        ),
      ],
    );
  }

  Widget _buildPhoneLayout(BuildContext context, bool isDark) {
    final cart = ref.watch(cartProvider);

    return Column(
      children: [
        Expanded(child: _buildProductSection(context, isDark)),

        // Cart summary bar at bottom
        if (cart.items.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Cart summary
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryWithOpacity10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            const Center(
                              child: Icon(Icons.shopping_cart_rounded, color: AppColors.primary, size: 22),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${cart.itemCount}',
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cart.items.length} item',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(cart.total),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _openCart(context),
                    icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
                    label: const Text('Bayar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _openCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.surfaceDark
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _CartBottomSheet(scrollController: controller),
        ),
      ),
    );
  }

  Widget _buildProductSection(BuildContext context, bool isDark) {
    final products = ref.watch(kasirProductsProvider);
    final categories = ref.watch(kasirCategoriesProvider);
    final selectedCat = ref.watch(kasirCategoryProvider);

    return Column(
      children: [
        // Search bar
        Container(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: AppSearchField(
            hint: 'Cari produk...',
            controller: _searchController,
            onChanged: (v) => ref.read(kasirSearchProvider.notifier).state = v,
            onClear: () => ref.read(kasirSearchProvider.notifier).state = '',
          ),
        ),

        // Category chips
        categories.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (cats) => Container(
            height: 40,
            color: isDark ? AppColors.surfaceDark : Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              itemCount: cats.length + 1,
              itemBuilder: (_, idx) {
                if (idx == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CategoryChip(
                      label: 'Semua',
                      isSelected: selectedCat == null,
                      onTap: () => ref.read(kasirCategoryProvider.notifier).state = null,
                    ),
                  );
                }
                final cat = cats[idx - 1];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _CategoryChip(
                    label: cat.name,
                    isSelected: selectedCat == cat.id,
                    onTap: () => ref.read(kasirCategoryProvider.notifier).state =
                        selectedCat == cat.id ? null : cat.id,
                  ),
                );
              },
            ),
          ),
        ),

        Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),

        // Products grid
        Expanded(
          child: products.when(
            loading: () => GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                childAspectRatio: 0.70,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 9,
              itemBuilder: (_, __) => const ShimmerProductCard(),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (prods) {
              if (prods.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(kasirProductsProvider);
                    ref.invalidate(kasirCategoriesProvider);
                    await ref.read(kasirProductsProvider.future);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: const EmptyStateWidget(
                          icon: Icons.inventory_2_outlined,
                          title: 'Produk Tidak Ditemukan',
                          subtitle: 'Coba kata kunci yang berbeda',
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(kasirProductsProvider);
                  ref.invalidate(kasirCategoriesProvider);
                  await ref.read(kasirProductsProvider.future);
                },
                child: GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    childAspectRatio: 0.70,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: prods.length,
                  itemBuilder: (_, idx) => _KasirProductCard(product: prods[idx]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCartSection(BuildContext context, bool isDark) {
    return const _CartPanel();
  }

  Future<void> _clearCartConfirm(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Keranjang'),
        content: const Text('Hapus semua item dari keranjang?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(cartProvider.notifier).clearCart();
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}

class _KasirProductCard extends ConsumerWidget {
  final ProductModel product;

  const _KasirProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartItem = cart.items.where((i) => i.productId == product.id).firstOrNull;
    final inCart = cartItem != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOutOfStock = product.isOutOfStock;

    return GestureDetector(
      onTap: isOutOfStock ? null : () {
        HapticFeedback.lightImpact();
        ref.read(cartProvider.notifier).addProduct(product);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isOutOfStock
              ? (isDark ? AppColors.borderDark : AppColors.borderLight)
              : inCart
                  ? AppColors.primaryWithOpacity10
                  : (isDark ? AppColors.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: inCart ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: inCart ? 1.5 : 1,
          ),
          boxShadow: inCart
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: inCart
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.primaryWithOpacity10,
                        borderRadius: BorderRadius.circular(10),
                        image: product.imagePath != null
                            ? DecorationImage(
                                image: FileImage(File(product.imagePath!)),
                                fit: BoxFit.cover,
                                colorFilter: isOutOfStock
                                    ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                    : null,
                              )
                            : null,
                      ),
                      child: product.imagePath == null
                          ? Icon(
                              Icons.fastfood_rounded,
                              color: isOutOfStock
                                  ? Colors.grey
                                  : inCart ? AppColors.primary : AppColors.primary.withValues(alpha: 0.7),
                              size: 26,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isOutOfStock
                          ? Colors.grey
                          : isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(product.price),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isOutOfStock ? Colors.grey : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOutOfStock ? 'Habis' : 'Stok: ${product.stock}',
                    style: TextStyle(
                      fontSize: 9,
                      color: isOutOfStock ? AppColors.error : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Cart quantity badge
            if (inCart)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${cartItem.quantity}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Cart Panel (for tablet)
class _CartPanel extends ConsumerWidget {
  const _CartPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                AppStrings.cart,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
              ),
              const Spacer(),
              if (cart.items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    '${cart.itemCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),

        // Items
        Expanded(
          child: cart.items.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.shopping_cart_outlined,
                  title: AppStrings.cartEmpty,
                  subtitle: AppStrings.cartEmptyDesc,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, idx) => _CartItemTile(item: cart.items[idx]),
                ),
        ),

        // Total & checkout
        if (cart.items.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal', style: TextStyle(fontSize: 13, color: textSecondary)),
                    Text(
                      CurrencyFormatter.format(cart.subtotal),
                      style: TextStyle(fontSize: 13, color: textPrimary),
                    ),
                  ],
                ),
                if (cart.discount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Diskon', style: TextStyle(fontSize: 13, color: textSecondary)),
                      Text(
                        '- ${CurrencyFormatter.format(cart.discount)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.success),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(
                      CurrencyFormatter.format(cart.total),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _checkout(context),
                    icon: const Icon(Icons.payment_rounded, size: 20),
                    label: const Text('Bayar Sekarang', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _checkout(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }
}

// Cart Bottom Sheet (for phone)
class _CartBottomSheet extends ConsumerWidget {
  final ScrollController scrollController;

  const _CartBottomSheet({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;


    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                '${AppStrings.cart} (${cart.itemCount} item)',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: cart.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, idx) => _CartItemTile(item: cart.items[idx]),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                  Text(
                    CurrencyFormatter.format(cart.total),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
                  },
                  icon: const Icon(Icons.payment_rounded, size: 22),
                  label: const Text('Bayar Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final TransactionItemModel item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;


    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryWithOpacity10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  CurrencyFormatter.format(item.productPrice),
                  style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          // Qty controls
          Row(
            children: [
              _QtyButton(
                icon: Icons.remove_rounded,
                onPressed: () => ref.read(cartProvider.notifier).removeProduct(item.productId),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 32),
                alignment: Alignment.center,
                child: Text(
                  '${item.quantity}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              _QtyButton(
                icon: Icons.add_rounded,
                onPressed: () {
                  if (item.product != null) {
                    ref.read(cartProvider.notifier).addProduct(item.product!);
                  }
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            CurrencyFormatter.format(item.subtotal),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => ref.read(cartProvider.notifier).removeItem(item.productId),
            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QtyButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.primaryWithOpacity10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }
}

// Checkout Screen
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _amountController = TextEditingController();
  String _selectedMethod = 'cash';
  bool _isProcessing = false;
  double _change = 0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_calculateChange);
  }

  void _calculateChange() {
    final cart = ref.read(cartProvider);
    final amount = double.tryParse(_amountController.text) ?? 0;
    setState(() => _change = amount - cart.total);
  }

  @override
  void dispose() {
    _amountController.removeListener(_calculateChange);
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    final cart = ref.read(cartProvider);
    final amount = _selectedMethod == 'transfer'
        ? cart.total
        : (double.tryParse(_amountController.text) ?? 0);

    if (_selectedMethod == 'cash' && amount < cart.total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah bayar kurang dari total'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final datasource = ref.read(transactionDatasourceProvider);
      final authState = ref.read(authProvider);
      final now = DateTime.now();

      final transaction = TransactionModel(
        transactionCode: datasource.generateTransactionCode(),
        userId: authState.user?.id,
        subtotal: cart.subtotal,
        discount: cart.discount,
        total: cart.total,
        paymentMethod: _selectedMethod,
        amountPaid: amount,
        changeAmount: _selectedMethod == 'cash' ? (amount - cart.total) : 0,
        items: cart.items,
        createdAt: now,
        updatedAt: now,
      );

      await datasource.createTransaction(transaction);
      ref.read(cartProvider.notifier).clearCart();

      // Invalidate dashboard
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(weeklySalesProvider);
      ref.invalidate(kasirProductsProvider);

      if (mounted) {
        _showSuccessDialog(amount - cart.total);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showSuccessDialog(double change) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 50),
            ),
            const SizedBox(height: 16),
            const Text(
              'Transaksi Berhasil!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (_selectedMethod == 'cash' && change > 0) ...[
              const SizedBox(height: 8),
              const Text(
                'Kembalian:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              Text(
                CurrencyFormatter.format(change),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Selesai'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Pembayaran'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Items summary
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text('Detail Pesanan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                        const Spacer(),
                        Text('${cart.items.length} item', style: TextStyle(fontSize: 12, color: textSecondary)),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ...cart.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.productName,
                            style: TextStyle(fontSize: 13, color: textPrimary),
                          ),
                        ),
                        Text(
                          '${item.quantity}x ${CurrencyFormatter.format(item.productPrice)}',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          CurrencyFormatter.format(item.subtotal),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.md),

            // Total card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Bayar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  Text(
                    CurrencyFormatter.format(cart.total),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.md),

            // Payment method
            Text('Metode Pembayaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Expanded(
                  child: _PaymentMethodCard(
                    icon: Icons.payments_rounded,
                    label: 'Tunai',
                    isSelected: _selectedMethod == 'cash',
                    onTap: () => setState(() => _selectedMethod = 'cash'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PaymentMethodCard(
                    icon: Icons.qr_code_2_rounded,
                    label: 'QRIS',
                    isSelected: _selectedMethod == 'qris',
                    onTap: () => setState(() => _selectedMethod = 'qris'),
                  ),
                ),
              ],
            ),

            if (_selectedMethod == 'cash') ...[
              const SizedBox(height: AppSizes.md),
              Text('Jumlah Bayar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
              const SizedBox(height: AppSizes.sm),
              AppTextField(
                label: 'Jumlah Uang',
                hint: '0',
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 16, right: 8),
                  child: Text('Rp', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),

              // Quick amount buttons
              const SizedBox(height: AppSizes.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _getQuickAmounts(cart.total).map((amount) {
                  return GestureDetector(
                    onTap: () {
                      _amountController.text = amount.toInt().toString();
                      _calculateChange();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryWithOpacity10,
                        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        CurrencyFormatter.format(amount),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (_change > 0) ...[
                const SizedBox(height: AppSizes.md),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kembalian:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.success)),
                      Text(
                        CurrencyFormatter.format(_change),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            const SizedBox(height: AppSizes.xl),

            GradientButton(
              label: 'Proses Pembayaran',
              onPressed: _processPayment,
              isLoading: _isProcessing,
              height: 56,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  List<double> _getQuickAmounts(double total) {
    final roundedTotal = (total / 1000).ceil() * 1000.0;
    return [
      roundedTotal,
      roundedTotal + 5000,
      roundedTotal + 10000,
      roundedTotal + 20000,
    ].where((a) => a >= total).take(4).toList();
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryWithOpacity10 : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? AppColors.primary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// End of transaction_screen.dart
