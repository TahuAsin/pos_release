import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/pdf_report_service.dart';
import '../../../data/repositories/app_providers.dart';
import '../../../presentation/widgets/shimmer_loading.dart';
import '../../../presentation/widgets/stat_card.dart';

enum ReportPeriod { today, week, month }

final reportPeriodProvider = StateProvider<ReportPeriod>((ref) => ReportPeriod.today);

final reportDatesProvider = Provider.autoDispose<({DateTime start, DateTime end})>((ref) {
  final period = ref.watch(reportPeriodProvider);
  final now = DateTime.now();
  final start = switch (period) {
    ReportPeriod.today => DateFormatter.startOfDay(now),
    ReportPeriod.week => now.subtract(const Duration(days: 6)),
    ReportPeriod.month => DateFormatter.startOfMonth(now),
  };
  final end = switch (period) {
    ReportPeriod.today => DateFormatter.endOfDay(now),
    ReportPeriod.week => DateFormatter.endOfDay(now),
    ReportPeriod.month => DateFormatter.endOfMonth(now),
  };
  return (start: start, end: end);
});

final reportSummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final datasource = ref.watch(transactionDatasourceProvider);
  final dates = ref.watch(reportDatesProvider);
  return await datasource.getPeriodSummary(dates.start, dates.end);
});

final reportChartProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final datasource = ref.watch(transactionDatasourceProvider);
  final period = ref.watch(reportPeriodProvider);
  final now = DateTime.now();

  if (period == ReportPeriod.month) {
    return await datasource.getMonthlySalesData(now.year, now.month);
  }
  return await datasource.getWeeklySalesData();
});

final productSalesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final datasource = ref.watch(transactionDatasourceProvider);
  final dates = ref.watch(reportDatesProvider);
  return await datasource.getProductSalesReport(dates.start, dates.end);
});

final profitLossProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final datasource = ref.watch(transactionDatasourceProvider);
  final dates = ref.watch(reportDatesProvider);
  return await datasource.getProfitLossReport(dates.start, dates.end);
});

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final dates = ref.read(reportDatesProvider);
      final txData = await ref.read(transactionDatasourceProvider).getTransactions(startDate: dates.start, endDate: dates.end, status: 'completed');
      final productsData = await ref.read(transactionDatasourceProvider).getProductSalesReport(dates.start, dates.end);
      final plData = await ref.read(transactionDatasourceProvider).getProfitLossReport(dates.start, dates.end);
      final chartData = await ref.read(reportChartProvider.future);
      final session = ref.read(cashRegisterProvider).session;
      
      final filePath = await PdfReportService.generateComprehensiveReport(
        transactions: txData,
        products: productsData,
        profitLoss: plData,
        chartData: chartData,
        session: session,
        startDate: dates.start,
        endDate: dates.end,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Laporan berhasil diekspor ke:\n$filePath'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengekspor: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.financialReport),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        actions: [
          _isExporting 
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error),
                tooltip: 'Export PDF',
                onPressed: _exportPdf,
              ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Penjualan'),
            Tab(text: 'Produk'),
            Tab(text: 'Laba Rugi'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Row(
                children: [
                  _PeriodTab(label: 'Hari Ini', value: ReportPeriod.today, current: ref.watch(reportPeriodProvider)),
                  _PeriodTab(label: 'Minggu', value: ReportPeriod.week, current: ref.watch(reportPeriodProvider)),
                  _PeriodTab(label: 'Bulan', value: ReportPeriod.month, current: ref.watch(reportPeriodProvider)),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSalesTab(isDark),
                _buildProductsTab(isDark),
                _buildProfitLossTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTab(bool isDark) {
    final summary = ref.watch(reportSummaryProvider);
    final chartData = ref.watch(reportChartProvider);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(reportSummaryProvider);
        ref.invalidate(reportChartProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            summary.when(
              loading: () => const Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: ShimmerStatCard()),
                      SizedBox(width: 12),
                      Expanded(child: ShimmerStatCard()),
                    ],
                  ),
                  SizedBox(height: 12),
                  ShimmerStatCard(),
                ],
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (data) {
                final revenue = (data['total_revenue'] as num?)?.toDouble() ?? 0;
                final cost = (data['total_cost'] as num?)?.toDouble() ?? 0;
                final profit = (data['total_profit'] as num?)?.toDouble() ?? 0;
                final txCount = (data['total_transactions'] as num?)?.toInt() ?? 0;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: AppStrings.revenue,
                            value: CurrencyFormatter.formatCompact(revenue),
                            icon: Icons.arrow_circle_up_rounded,
                            iconColor: AppColors.success,
                            iconBgColor: AppColors.success.withValues(alpha: 0.1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: AppStrings.expenses,
                            value: CurrencyFormatter.formatCompact(cost),
                            icon: Icons.arrow_circle_down_rounded,
                            iconColor: AppColors.error,
                            iconBgColor: AppColors.error.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: AppStrings.profit,
                            value: CurrencyFormatter.formatCompact(profit),
                            icon: Icons.trending_up_rounded,
                            iconColor: AppColors.primary,
                            iconBgColor: AppColors.primaryWithOpacity10,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Transaksi',
                            value: '$txCount',
                            subtitle: 'Total transaksi',
                            icon: Icons.receipt_long_rounded,
                            iconColor: AppColors.info,
                            iconBgColor: AppColors.info.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: AppSizes.lg),
            Text(AppStrings.salesChart, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
            const SizedBox(height: AppSizes.md),

            chartData.when(
              loading: () => const ShimmerBox(width: double.infinity, height: 220, radius: 16),
              error: (_, __) => const SizedBox.shrink(),
              data: (data) => _buildBarChart(context, data, isDark),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTab(bool isDark) {
    final productsData = ref.watch(productSalesProvider);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(productSalesProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.md),
        child: productsData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
          data: (data) {
            if (data.isEmpty) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text('Belum ada data produk', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ));
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rincian Produk Terjual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: AppSizes.md),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    itemBuilder: (context, index) {
                      final item = data[index];
                      final name = item['product_name'] ?? '';
                      final qty = (item['total_qty'] as num?)?.toInt() ?? 0;
                      final revenue = (item['total_revenue'] as num?)?.toDouble() ?? 0.0;
                      final profit = (item['total_profit'] as num?)?.toDouble() ?? 0.0;
                      
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primaryWithOpacity10,
                              child: Text('${index + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                                  Text('$qty Terjual', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(CurrencyFormatter.formatCompact(revenue), style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                                Text('Laba: ${CurrencyFormatter.formatCompact(profit)}', style: const TextStyle(fontSize: 12, color: AppColors.success)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfitLossTab(bool isDark) {
    final plData = ref.watch(profitLossProvider);
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(profitLossProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.md),
        child: plData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
          data: (data) {
            final revenue = data['revenue'] as double;
            final discount = data['discount'] as double;
            final cogs = data['cogs'] as double;
            final grossProfit = data['gross_profit'] as double;
            final operationalCosts = data['operational_costs'] as double;
            final netProfit = data['net_profit'] as double;
            
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pendapatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  _buildPlRow('Penjualan Kotor', revenue),
                  _buildPlRow('Diskon', discount, isNegative: true),
                  const Divider(),
                  _buildPlRow('Penjualan Bersih', revenue - discount, isBold: true),
                  const SizedBox(height: 24),
                  
                  const Text('Harga Pokok Penjualan (HPP)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  _buildPlRow('HPP', cogs, isNegative: true),
                  const Divider(),
                  _buildPlRow('Laba Kotor', grossProfit, isBold: true, color: AppColors.primary),
                  const SizedBox(height: 24),
                  
                  const Text('Biaya Operasional', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  _buildPlRow('Total Biaya', operationalCosts, isNegative: true),
                  const Divider(thickness: 2),
                  _buildPlRow('Laba Bersih', netProfit, isBold: true, color: netProfit >= 0 ? AppColors.success : AppColors.error),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlRow(String label, double value, {bool isNegative = false, bool isBold = false, Color? color}) {
    final valStr = value == 0 ? 'Rp 0' : CurrencyFormatter.format(value);
    final displayStr = isNegative && value > 0 ? '( $valStr )' : valStr;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            displayStr, 
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isNegative && value > 0 ? AppColors.error : null),
            )
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, List<Map<String, dynamic>> data, bool isDark) {
    if (data.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Center(
          child: Text(
            'Belum ada data',
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
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          titlesData: FlTitlesData(
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
                      fontSize: 9,
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
                  try {
                    final date = DateTime.parse(dateStr);
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormatter.formatDayMonth(date),
                        style: TextStyle(
                          fontSize: 9,
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
          barGroups: data.asMap().entries.map((e) {
            final revenue = (e.value['total_revenue'] as num?)?.toDouble() ?? 0;
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: revenue,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
          maxY: maxRevenue > 0 ? maxRevenue * 1.2 : 100000,
        ),
      ),
    );
  }
}

class _PeriodTab extends ConsumerWidget {
  final String label;
  final ReportPeriod value;
  final ReportPeriod current;

  const _PeriodTab({required this.label, required this.value, required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(reportPeriodProvider.notifier).state = value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
            ),
          ),
        ),
      ),
    );
  }
}
