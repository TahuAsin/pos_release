import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';

import '../../../data/models/product_model.dart';
import '../../../data/repositories/app_providers.dart';
import '../../../presentation/widgets/empty_state.dart';
import '../../../presentation/widgets/shimmer_loading.dart';
import '../../transaction/presentation/transaction_screen.dart';
import '../../products/presentation/products_screen.dart';

final stockProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final datasource = ref.watch(productDatasourceProvider);
  return await datasource.getProducts(isActive: true);
});

final lowStockProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final datasource = ref.watch(productDatasourceProvider);
  return await datasource.getLowStockProducts();
});

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.stockManagement),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Semua Produk'),
            Tab(text: 'Stok Rendah'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(stockProductsProvider);
          ref.invalidate(lowStockProvider);
        },
        color: AppColors.primary,
        child: TabBarView(
          controller: _tabController,
          children: [
            _AllStockTab(onRefresh: () {
              ref.invalidate(stockProductsProvider);
              ref.invalidate(lowStockProvider);
            }),
            _LowStockTab(onRefresh: () {
              ref.invalidate(stockProductsProvider);
              ref.invalidate(lowStockProvider);
            }),
          ],
        ),
      ),
    );
  }
}

class _AllStockTab extends ConsumerWidget {
  final VoidCallback onRefresh;

  const _AllStockTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(stockProductsProvider);

    return products.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(AppSizes.md),
        itemCount: 6,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: ShimmerListItem(),
        ),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (prods) {
        if (prods.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.inventory_outlined,
            title: 'Tidak ada produk',
            subtitle: 'Tambahkan produk terlebih dahulu',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSizes.md),
          itemCount: prods.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, idx) => _StockItemCard(product: prods[idx], onRefresh: onRefresh),
        );
      },
    );
  }
}

class _LowStockTab extends ConsumerWidget {
  final VoidCallback onRefresh;

  const _LowStockTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(lowStockProvider);

    return products.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(AppSizes.md),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: ShimmerListItem(),
        ),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (prods) {
        if (prods.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.check_circle_outline_rounded,
            title: AppStrings.noLowStock,
            subtitle: 'Semua produk masih memiliki stok yang cukup',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSizes.md),
          itemCount: prods.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, idx) => _StockItemCard(
            product: prods[idx],
            onRefresh: onRefresh,
            highlightLow: true,
          ),
        );
      },
    );
  }
}

class _StockItemCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onRefresh;
  final bool highlightLow;

  const _StockItemCard({
    required this.product,
    required this.onRefresh,
    this.highlightLow = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;


    final stockColor = product.isOutOfStock
        ? AppColors.error
        : product.isLowStock
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (highlightLow && product.isLowStock)
              ? stockColor.withValues(alpha: 0.4)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: (highlightLow && product.isLowStock) ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: stockColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.fastfood_rounded, color: stockColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  CurrencyFormatter.format(product.price),
                  style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                // Stock bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: product.stock == 0
                              ? 0
                              : (product.stock / 50).clamp(0.0, 1.0),
                          backgroundColor: stockColor.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(stockColor),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${product.stock} pcs',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: stockColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _showUpdateStockDialog(context),
            icon: const Icon(Icons.edit_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryWithOpacity10,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateStockDialog(BuildContext context) {
    final controller = TextEditingController(text: product.stock.toString());
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          return AlertDialog(
            title: Text('Update Stok: ${product.name}'),
            content: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Jumlah Stok',
                suffixText: 'pcs',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newStock = int.tryParse(controller.text) ?? 0;
                  await ref.read(productDatasourceProvider).updateStock(product.id!, newStock);
                  onRefresh();
                  // Refresh related screens
                  ref.invalidate(kasirProductsProvider);
                  ref.invalidate(productsProvider);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Stok berhasil diperbarui'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }
}
