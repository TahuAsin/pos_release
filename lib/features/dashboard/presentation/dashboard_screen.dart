import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/app_providers.dart';
import '../../../presentation/widgets/stat_card.dart';
import '../../../presentation/widgets/shimmer_loading.dart';
import '../../transaction/presentation/transaction_screen.dart';
import '../../products/presentation/products_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../expenses/presentation/expenses_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../auth/presentation/account_settings_screen.dart';
import '../../stock/presentation/stock_screen.dart';
import '../../backup/presentation/backup_screen.dart';
import '../../auth/presentation/login_screen.dart';
import 'dart:async';

// Dashboard providers
final dashboardSummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final datasource = ref.watch(transactionDatasourceProvider);
  return await datasource.getDailySummary(DateTime.now());
});

final weeklySalesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final datasource = ref.watch(transactionDatasourceProvider);
  return await datasource.getWeeklySalesData();
});

final topProductsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final datasource = ref.watch(transactionDatasourceProvider);
  return await datasource.getTopProducts(limit: 5);
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final user = ref.watch(authProvider).user;
    final summary = ref.watch(dashboardSummaryProvider);
    final weeklySales = ref.watch(weeklySalesProvider);
    final topProducts = ref.watch(topProductsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(weeklySalesProvider);
          ref.invalidate(topProductsProvider);
        },
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverAppBar(
              expandedHeight: 170,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF1E5AAE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.point_of_sale_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      AppStrings.appName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      user?.businessName ?? AppStrings.appTagline,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                                  onPressed: () {},
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.md),
                          Text(
                            'Selamat datang, ${user?.fullName ?? 'Admin'}! 👋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            DateFormatter.formatDate(DateTime.now()),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick action button
                    _buildQuickSaleCard(context),
                    const SizedBox(height: AppSizes.lg),

                    // Stat cards
                    Text(
                      AppStrings.todaySales,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),

                    summary.when(
                      loading: () => const Row(
                        children: [
                          Expanded(child: ShimmerStatCard()),
                          SizedBox(width: 12),
                          Expanded(child: ShimmerStatCard()),
                        ],
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (data) => Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: StatCard(
                                  title: AppStrings.totalSales,
                                  value: CurrencyFormatter.formatCompact(
                                    (data['total_revenue'] as num?)?.toDouble() ?? 0,
                                  ),
                                  subtitle: 'Hari ini',
                                  icon: Icons.payments_rounded,
                                  iconColor: AppColors.primary,
                                  iconBgColor: AppColors.primaryWithOpacity10,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatCard(
                                  title: AppStrings.totalTransactions,
                                  value: '${(data['total_transactions'] as num?)?.toInt() ?? 0}',
                                  subtitle: 'Transaksi',
                                  icon: Icons.receipt_long_rounded,
                                  iconColor: AppColors.info,
                                  iconBgColor: AppColors.info.withValues(alpha: 0.1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          StatCard(
                            title: AppStrings.totalProfit,
                            value: CurrencyFormatter.formatCompact(
                              (data['total_profit'] as num?)?.toDouble() ?? 0,
                            ),
                            subtitle: 'Laba bersih hari ini',
                            icon: Icons.trending_up_rounded,
                            iconColor: AppColors.success,
                            iconBgColor: AppColors.success.withValues(alpha: 0.1),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSizes.lg),

                    // Weekly chart
                    Text(
                      AppStrings.salesChart,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      '7 hari terakhir',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    const SizedBox(height: AppSizes.md),

                    weeklySales.when(
                      loading: () => const ShimmerBox(width: double.infinity, height: 200, radius: 16),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (data) => _buildWeeklyChart(context, data, isDark),
                    ),

                    const SizedBox(height: AppSizes.lg),

                    // Top products
                    Text(
                      AppStrings.topProducts,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),

                    topProducts.when(
                      loading: () => Column(
                        children: List.generate(3, (_) => const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: ShimmerListItem(),
                        )),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (data) => _buildTopProducts(context, data, isDark),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSaleCard(BuildContext context) {
    final cashRegisterState = ref.watch(cashRegisterProvider);
    final isOpen = cashRegisterState.isOpen;
    
    return GestureDetector(
      onTap: () {
        if (isOpen) {
          _showCloseRegisterDialog(context);
        } else {
          _showOpenRegisterDialog(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isOpen 
              ? [AppColors.error, const Color(0xFFD32F2F)]
              : [AppColors.secondary, const Color(0xFF00A895)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: (isOpen ? AppColors.error : AppColors.secondary).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(isOpen ? Icons.lock_rounded : Icons.point_of_sale_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOpen ? 'Tutup Kasir' : 'Buka Kasir',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    isOpen ? 'Akhiri sesi kasir saat ini' : 'Mulai transaksi baru',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isOpen) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Modal Awal', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  Text(
                    CurrencyFormatter.formatCompact(cashRegisterState.session?.openingAmount ?? 0),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(width: 12),
            ],
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _showOpenRegisterDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Image/Icon
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.secondary, Color(0xFF00A895)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.point_of_sale_rounded, size: 48, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      'Buka Kasir',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mulai Sesi Baru',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Masukkan nominal uang modal awal yang ada di laci kasir saat ini.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Nominal Modal Awal',
                        prefixText: 'Rp ',
                        prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.primaryWithOpacity10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              final amount = double.tryParse(controller.text) ?? 0;
                              await ref.read(cashRegisterProvider.notifier).openRegister(amount);
                              if (mounted) Navigator.pop(ctx);
                            },
                            child: const Text('Buka Kasir', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCloseRegisterDialog(BuildContext context) {
    final controller = TextEditingController();
    final session = ref.read(cashRegisterProvider).session;
    if (session == null) return;
    
    // We update totals first to get accurate expected amount before showing dialog
    ref.read(cashRegisterProvider.notifier).updateTotals().then((_) {
      if (!mounted) return;
      final updatedSession = ref.read(cashRegisterProvider).session;
      if (updatedSession == null) return;
      
      final expected = updatedSession.calculatedExpectedAmount;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Image/Icon
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.error, Color(0xFFD32F2F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.lock_rounded, size: 48, color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        'Tutup Kasir',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            _infoRow('Modal Awal', CurrencyFormatter.format(updatedSession.openingAmount)),
                            _infoRow('Penjualan Tunai', CurrencyFormatter.format(updatedSession.totalCashSales)),
                            const Divider(height: 24),
                            _infoRow('Total Kas Seharusnya', CurrencyFormatter.format(expected), isBold: true, color: AppColors.primary),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Validasi Saldo Laci',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masukkan jumlah uang fisik yang ada di dalam laci kasir saat ini.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          labelText: 'Uang Fisik Aktual',
                          prefixText: 'Rp ',
                          prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                          filled: true,
                          fillColor: AppColors.error.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.error, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Batal'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                if (controller.text.isEmpty) return;
                                final actual = double.tryParse(controller.text) ?? 0;
                                await ref.read(cashRegisterProvider.notifier).closeRegister(actual, null);
                                if (mounted) Navigator.pop(ctx);
                              },
                              child: const Text('Tutup Kasir', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _infoRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: isBold ? null : Colors.grey[600])),
          Text(
            value, 
            style: TextStyle(
              fontSize: 13, 
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(BuildContext context, List<Map<String, dynamic>> data, bool isDark) {
    if (data.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Center(
          child: Text(
            'Belum ada data penjualan',
            style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ),
      );
    }

    final maxRevenue = data.fold<double>(0, (max, item) {
      final rev = (item['total_revenue'] as num?)?.toDouble() ?? 0;
      return rev > max ? rev : max;
    });

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxRevenue > 0 ? maxRevenue / 4 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 55,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(
                    CurrencyFormatter.formatCompact(value).replaceAll('Rp ', ''),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                  final dateStr = data[idx]['date'] as String? ?? '';
                  if (dateStr.isEmpty) return const SizedBox.shrink();
                  try {
                    final date = DateTime.parse(dateStr);
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormatter.formatDayMonth(date),
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    );
                  } catch (_) {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((e) {
                final revenue = (e.value['total_revenue'] as num?)?.toDouble() ?? 0;
                return FlSpot(e.key.toDouble(), revenue);
              }).toList(),
              isCurved: true,
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.secondary,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.secondary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProducts(BuildContext context, List<Map<String, dynamic>> products, bool isDark) {
    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Center(
          child: Text(
            'Belum ada data produk terjual',
            style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        children: products.asMap().entries.map((entry) {
          final idx = entry.key;
          final product = entry.value;
          final name = product['product_name'] as String? ?? '';
          final qty = (product['total_qty'] as num?)?.toInt() ?? 0;
          final revenue = (product['total_revenue'] as num?)?.toDouble() ?? 0;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _getRankColor(idx).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _getRankColor(idx),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Terjual: $qty pcs',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatCompact(revenue),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (idx < products.length - 1)
                Divider(
                  height: 1,
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  indent: 60,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0: return const Color(0xFFF59E0B);
      case 1: return const Color(0xFF6B7280);
      case 2: return const Color(0xFFB45309);
      default: return AppColors.primary;
    }
  }
}

// Main shell with bottom navigation
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ProductsShell(),
    TransactionScreen(),
    HistoryShell(),
    MoreMenuScreen(),
  ];

  void setIndex(int index) {
    if (index == 2) {
      final session = ref.read(cashRegisterProvider).session;
      if (session == null || session.status != 'open') {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Akses Ditolak'),
            content: const Text('Silahkan buka kasir terlebih dahulu untuk memulai transaksi.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Mengerti'),
              ),
            ],
          ),
        );
        return;
      }
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, Icons.dashboard_outlined, 'Dashboard'),
                _buildNavItem(1, Icons.inventory_2_rounded, Icons.inventory_2_outlined, 'Produk'),
                _buildCenterNavItem(),
                _buildNavItem(3, Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Riwayat'),
                _buildNavItem(4, Icons.grid_view_rounded, Icons.grid_view_outlined, 'Lainnya'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setIndex(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                key: ValueKey(isSelected),
                size: 24,
                color: isSelected ? AppColors.primary : (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavItem() {
    final isSelected = _currentIndex == 2;
    return GestureDetector(
      onTap: () => setIndex(2),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isSelected ? 0.4 : 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}

// Placeholder screens for shells
class ProductsShell extends StatelessWidget {
  const ProductsShell({super.key});
  @override
  Widget build(BuildContext context) => const ProductsScreen();
}

class HistoryShell extends StatelessWidget {
  const HistoryShell({super.key});
  @override
  Widget build(BuildContext context) => const HistoryScreen();
}

class MoreMenuScreen extends ConsumerWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lainnya'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
            tooltip: 'Ganti tema',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          user?.businessName ?? AppStrings.appName,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                        ),
                        Text(
                          '@${user?.username ?? ''}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            Text('Fitur', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary)),
            const SizedBox(height: AppSizes.sm),

            _buildMenuSection(context, cardColor, isDark, textPrimary, [
              _MenuItem(Icons.bar_chart_rounded, AppColors.info, 'Laporan Keuangan', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
              }),
              _MenuItem(Icons.inventory_rounded, AppColors.warning, 'Manajemen Stok', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StockScreen()));
              }),
              _MenuItem(Icons.money_off_rounded, AppColors.error, 'Pengeluaran', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen()));
              }),
              _MenuItem(Icons.backup_rounded, AppColors.success, 'Backup & Restore', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen()));
              }),
            ]),

            const SizedBox(height: AppSizes.lg),

            Text('Akun', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary)),
            const SizedBox(height: AppSizes.sm),

            _buildMenuSection(context, cardColor, isDark, textPrimary, [
              _MenuItem(
                Icons.manage_accounts_rounded, 
                AppColors.info, 
                'Pengaturan Akun', 
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountSettingsScreen())),
              ),
              _MenuItem(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                isDark ? AppColors.warning : AppColors.primary,
                isDark ? 'Mode Terang' : 'Mode Gelap',
                () => ref.read(themeProvider.notifier).toggleTheme(),
              ),
              _MenuItem(Icons.logout_rounded, AppColors.error, 'Keluar', () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Konfirmasi Keluar'),
                    content: const Text('Apakah Anda yakin ingin keluar?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Keluar', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await ref.read(authProvider.notifier).logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }
              }),
            ]),

            const SizedBox(height: AppSizes.lg),

            Center(
              child: Text(
                'ALFlow Kasir v1.0.0\n© ${DateTime.now().year} ALFlow Business',
                style: TextStyle(fontSize: 12, color: textSecondary, height: 1.6),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    Color cardColor,
    bool isDark,
    Color textPrimary,
    List<_MenuItem> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(idx == 0 ? 16 : 0),
                    topRight: Radius.circular(idx == 0 ? 16 : 0),
                    bottomLeft: Radius.circular(idx == items.length - 1 ? 16 : 0),
                    bottomRight: Radius.circular(idx == items.length - 1 ? 16 : 0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item.icon, size: 20, color: item.color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (idx < items.length - 1)
                Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight, indent: 68),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.color, this.title, this.onTap);
}

// End of dashboard_screen.dart
