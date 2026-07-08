import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';

import '../../../data/models/product_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/app_providers.dart';
import '../../../presentation/widgets/app_button.dart';
import '../../../presentation/widgets/app_text_field.dart';
import '../../../presentation/widgets/empty_state.dart';
import '../../../presentation/widgets/shimmer_loading.dart';
import '../../transaction/presentation/transaction_screen.dart';
import '../../stock/presentation/stock_screen.dart';

// Providers
final selectedCategoryProvider = StateProvider<int?>((ref) => null);
final productSearchProvider = StateProvider<String>((ref) => '');

final productsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final datasource = ref.watch(productDatasourceProvider);
  final search = ref.watch(productSearchProvider);
  final categoryId = ref.watch(selectedCategoryProvider);
  return await datasource.getProducts(
    searchQuery: search.isEmpty ? null : search,
    categoryId: categoryId,
    isActive: true,
  );
});

final categoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final datasource = ref.watch(productDatasourceProvider);
  return await datasource.getCategories();
});

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = TextEditingController();
  bool _isGridView = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final products = ref.watch(productsProvider);
    final categories = ref.watch(categoriesProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(AppStrings.products),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'Tampilan List' : 'Tampilan Grid',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter
          Container(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: AppSearchField(
              hint: 'Cari produk...',
              controller: _searchController,
              onChanged: (v) => ref.read(productSearchProvider.notifier).state = v,
              onClear: () => ref.read(productSearchProvider.notifier).state = '',
            ),
          ),

          // Category chips
          categories.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (cats) => Container(
              height: 44,
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemCount: cats.length + 1,
                itemBuilder: (context, idx) {
                  if (idx == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Semua'),
                        selected: selectedCat == null,
                        onSelected: (_) => ref.read(selectedCategoryProvider.notifier).state = null,
                        selectedColor: AppColors.primaryWithOpacity10,
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selectedCat == null ? AppColors.primary : null,
                          fontWeight: selectedCat == null ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  final cat = cats[idx - 1];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat.name),
                      selected: selectedCat == cat.id,
                      onSelected: (_) {
                        ref.read(selectedCategoryProvider.notifier).state =
                            selectedCat == cat.id ? null : cat.id;
                      },
                      selectedColor: AppColors.primaryWithOpacity10,
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selectedCat == cat.id ? AppColors.primary : null,
                        fontWeight: selectedCat == cat.id ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),

          // Products list/grid
          Expanded(
            child: products.when(
              loading: () => _isGridView
                  ? GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 180,
                        childAspectRatio: 0.70,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: 6,
                      itemBuilder: (_, __) => const ShimmerProductCard(),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 5,
                      itemBuilder: (_, __) => const ShimmerListItem(),
                    ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (prods) {
                if (prods.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.inventory_2_outlined,
                    title: AppStrings.noProducts,
                    subtitle: AppStrings.noProductsDesc,
                    actionLabel: AppStrings.addProduct,
                    onAction: () => _showAddProductDialog(context),
                  );
                }

                if (_isGridView) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180,
                      childAspectRatio: 0.70,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: prods.length,
                    itemBuilder: (_, idx) => _ProductCard(
                      product: prods[idx],
                      onRefresh: () => ref.invalidate(productsProvider),
                    ),
                  );
                } else {
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: prods.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, idx) => _ProductListItem(
                      product: prods[idx],
                      onRefresh: () => ref.invalidate(productsProvider),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditProductSheet(
        onSaved: () => ref.invalidate(productsProvider),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onRefresh;

  const _ProductCard({required this.product, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;


    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddEditProductSheet(
          product: product,
          onSaved: onRefresh,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image / icon
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primaryWithOpacity10,
                    borderRadius: BorderRadius.circular(12),
                    image: product.imagePath != null
                        ? DecorationImage(
                            image: FileImage(File(product.imagePath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: product.imagePath == null
                      ? const Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 36)
                      : null,
                ),
              ),
              const SizedBox(height: 10),

              // Name
              Text(
                product.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Price
              Text(
                CurrencyFormatter.format(product.price),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),

              // Stock badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: product.isLowStock
                          ? AppColors.stockLow.withValues(alpha: 0.1)
                          : AppColors.stockGood.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: product.isLowStock ? AppColors.stockLow : AppColors.stockGood,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Stok: ${product.stock}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: product.isLowStock ? AppColors.stockLow : AppColors.stockGood,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onRefresh;

  const _ProductListItem({required this.product, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddEditProductSheet(product: product, onSaved: onRefresh),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primaryWithOpacity10,
                  borderRadius: BorderRadius.circular(12),
                  image: product.imagePath != null
                      ? DecorationImage(
                          image: FileImage(File(product.imagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product.imagePath == null
                    ? const Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 26)
                    : null,
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
                    if (product.categoryName != null)
                      Text(
                        product.categoryName!,
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(product.price),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: product.isLowStock
                          ? AppColors.stockLow.withValues(alpha: 0.1)
                          : AppColors.stockGood.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${product.stock} pcs',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: product.isLowStock ? AppColors.stockLow : AppColors.stockGood,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Modal: ${CurrencyFormatter.format(product.costPrice)}',
                    style: TextStyle(fontSize: 10, color: textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Add/Edit Product Bottom Sheet
class AddEditProductSheet extends ConsumerStatefulWidget {
  final ProductModel? product;
  final VoidCallback onSaved;

  const AddEditProductSheet({super.key, this.product, required this.onSaved});

  @override
  ConsumerState<AddEditProductSheet> createState() => _AddEditProductSheetState();
}

class _AddEditProductSheetState extends ConsumerState<AddEditProductSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _costController;
  late TextEditingController _stockController;
  int? _selectedCategoryId;
  String? _imagePath;
  bool _isSaving = false;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toInt().toString() ?? '');
    _costController = TextEditingController(text: widget.product?.costPrice.toInt().toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? '0');
    _selectedCategoryId = widget.product?.categoryId;
    _imagePath = widget.product?.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _deleteCategory(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Hapus kategori "$name"?\n\nSemua produk dalam kategori ini tidak akan memiliki kategori.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(productDatasourceProvider).deleteCategory(id);
        await ref.refresh(categoriesProvider.future);
        
        if (!mounted) return;
        setState(() {
          _selectedCategoryId = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori berhasil dihapus'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus kategori: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final catController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kategori Baru'),
        content: TextField(
          controller: catController,
          decoration: const InputDecoration(
            hintText: 'Nama Kategori',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              final name = catController.text.trim();
              if (name.isNotEmpty) Navigator.pop(ctx, name);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      try {
        final datasource = ref.read(productDatasourceProvider);
        final newCategory = CategoryModel(
          name: result,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final newId = await datasource.insertCategory(newCategory);
        
        await ref.refresh(categoriesProvider.future);
        
        if (!mounted) return;
        setState(() {
          _selectedCategoryId = newId;
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambah kategori: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    try {
      final datasource = ref.read(productDatasourceProvider);
      final now = DateTime.now();

      final product = ProductModel(
        id: widget.product?.id,
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        costPrice: _costController.text.isEmpty ? 0 : double.parse(_costController.text),
        stock: int.parse(_stockController.text),
        categoryId: _selectedCategoryId,
        imagePath: _imagePath,
        createdAt: widget.product?.createdAt ?? now,
        updatedAt: now,
      );

      if (isEditing) {
        await datasource.updateProduct(product);
      } else {
        await datasource.insertProduct(product);
      }

      if (!mounted) return;
      widget.onSaved();
      // Refresh all related screens
      ref.invalidate(kasirProductsProvider);
      ref.invalidate(kasirCategoriesProvider);
      ref.invalidate(stockProductsProvider);
      ref.invalidate(lowStockProvider);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Produk berhasil diperbarui' : 'Produk berhasil ditambahkan'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _delete() async {
    if (widget.product?.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Hapus "${widget.product!.name}"?'),
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
      await ref.read(productDatasourceProvider).deleteProduct(widget.product!.id!);
      widget.onSaved();
      // Refresh all related screens
      ref.invalidate(kasirProductsProvider);
      ref.invalidate(kasirCategoriesProvider);
      ref.invalidate(stockProductsProvider);
      ref.invalidate(lowStockProvider);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ref.watch(categoriesProvider);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        margin: const EdgeInsets.only(top: 60),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    isEditing ? AppStrings.editProduct : AppStrings.addProduct,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const Spacer(),
                  if (isEditing)
                    IconButton(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: AppSizes.md),

                    // Image Picker
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final result = await FilePicker.pickFiles(type: FileType.image);
                          if (result != null && result.files.single.path != null) {
                            setState(() => _imagePath = result.files.single.path);
                          }
                        },
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.primaryWithOpacity10,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                              width: 1,
                            ),
                            image: _imagePath != null
                                ? DecorationImage(
                                    image: FileImage(File(_imagePath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _imagePath == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 28),
                                    SizedBox(height: 4),
                                    Text('Foto', style: TextStyle(fontSize: 10, color: AppColors.primary)),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ),
                    if (_imagePath != null)
                      Center(
                        child: TextButton(
                          onPressed: () => setState(() => _imagePath = null),
                          child: const Text('Hapus Foto', style: TextStyle(color: AppColors.error)),
                        ),
                      ),
                    const SizedBox(height: AppSizes.md),

                    AppTextField(
                      label: AppStrings.productName,
                      hint: 'Nama produk',
                      controller: _nameController,
                      validator: (v) => v?.isEmpty == true ? 'Nama produk wajib diisi' : null,
                    ),
                    const SizedBox(height: AppSizes.md),

                    AppTextField(
                      label: AppStrings.productPrice,
                      hint: '0',
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 12, right: 4),
                        child: Text('Rp', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      validator: (v) {
                        if (v?.isEmpty == true) return 'Wajib diisi';
                        if ((double.tryParse(v!) ?? 0) <= 0) return 'Harus > 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.md),

                    AppTextField(
                      label: AppStrings.productStock,
                      hint: '0',
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => v?.isEmpty == true ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Category
                    categories.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (cats) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _selectedCategoryId,
                                decoration: InputDecoration(
                                  labelText: AppStrings.productCategory,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('Pilih kategori')),
                                  ...cats.map((cat) => DropdownMenuItem(
                                    value: cat.id,
                                    child: Text(cat.name),
                                  )),
                                  const DropdownMenuItem(
                                    value: -1,
                                    child: Row(
                                      children: [
                                        Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                                        SizedBox(width: 8),
                                        Text('Tambah Kategori Baru...', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v == -1) {
                                    _showAddCategoryDialog(context);
                                  } else {
                                    setState(() => _selectedCategoryId = v);
                                  }
                                },
                              ),
                            ),
                            if (_selectedCategoryId != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                tooltip: 'Hapus Kategori',
                                onPressed: () {
                                  final selectedCat = cats.firstWhere((c) => c.id == _selectedCategoryId);
                                  _deleteCategory(selectedCat.id!, selectedCat.name);
                                },
                              ),
                            ],
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: AppSizes.xl),

                    GradientButton(
                      label: isEditing ? 'Perbarui Produk' : 'Simpan Produk',
                      onPressed: _save,
                      isLoading: _isSaving,
                    ),
                    const SizedBox(height: AppSizes.md),
                  ],
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
