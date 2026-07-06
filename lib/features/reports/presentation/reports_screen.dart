import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';

import '../../../data/repositories/app_providers.dart';
import '../../../presentation/widgets/shimmer_loading.dart';
import '../../../presentation/widgets/stat_card.dart';

enum ReportPeriod { today, week, month }

final reportPeriodProvider = StateProvider<ReportPeriod>((ref) => ReportPeriod.today);

final reportSummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final datasource = ref.watch(transactionDatasourceProvider);
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

  return await datasource.getPeriodSummary(start, end);
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

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    final period = ref.watch(reportPeriodProvider);
    final summary = ref.watch(reportSummaryProvider);
    final chartData = ref.watch(reportChartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.financialReport),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(reportSummaryProvider);
          ref.invalidate(reportChartProvider);
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period selector
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    _PeriodTab(label: 'Hari Ini', value: ReportPeriod.today, current: period),
                    _PeriodTab(label: 'Minggu', value: ReportPeriod.week, current: period),
                    _PeriodTab(label: 'Bulan', value: ReportPeriod.month, current: period),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Summary cards
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

              // Chart
              Text(
                AppStrings.salesChart,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
              ),
              const SizedBox(height: AppSizes.md),

              chartData.when(
                loading: () => const ShimmerBox(width: double.infinity, height: 220, radius: 16),
                error: (_, __) => const SizedBox.shrink(),
                data: (data) => _buildBarChart(context, data, isDark),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
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
