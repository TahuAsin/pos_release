import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';

import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/app_providers.dart';
import '../../../presentation/widgets/empty_state.dart';
import '../../../presentation/widgets/shimmer_loading.dart';
import '../../../core/services/pdf_report_service.dart';

final historyFilterDateProvider = StateProvider.autoDispose<DateTimeRange?>((ref) => null);

final historyProvider = FutureProvider.autoDispose<List<TransactionModel>>((ref) async {
  final datasource = ref.watch(transactionDatasourceProvider);
  final dateRange = ref.watch(historyFilterDateProvider);
  
  return await datasource.getTransactions(
    limit: 100,
    startDate: dateRange?.start,
    endDate: dateRange?.end,
  );
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactions = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.transactionHistory),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Export PDF',
            onPressed: () async {
              final txs = transactions.valueOrNull;
              if (txs == null || txs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tidak ada data untuk diekspor')),
                );
                return;
              }
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Membuat Laporan PDF...')),
                );
                final path = await PdfReportService.generateAndSaveReport(txs);
                if (path != null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Berhasil! File tersimpan di:\n$path'),
                        duration: const Duration(seconds: 4),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter Tanggal',
            onSelected: (value) {
              final now = DateTime.now();
              DateTimeRange? newRange;

              switch (value) {
                case 'today':
                  newRange = DateTimeRange(
                    start: DateTime(now.year, now.month, now.day),
                    end: DateTime(now.year, now.month, now.day, 23, 59, 59),
                  );
                  break;
                case 'week':
                  newRange = DateTimeRange(
                    start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6)),
                    end: DateTime(now.year, now.month, now.day, 23, 59, 59),
                  );
                  break;
                case 'month':
                  newRange = DateTimeRange(
                    start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29)),
                    end: DateTime(now.year, now.month, now.day, 23, 59, 59),
                  );
                  break;
                case 'all':
                default:
                  newRange = null;
                  break;
              }

              ref.read(historyFilterDateProvider.notifier).state = newRange;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('Semua Transaksi'),
              ),
              const PopupMenuItem(
                value: 'today',
                child: Text('Hari Ini'),
              ),
              const PopupMenuItem(
                value: 'week',
                child: Text('7 Hari Terakhir'),
              ),
              const PopupMenuItem(
                value: 'month',
                child: Text('30 Hari Terakhir'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(historyProvider),
        color: AppColors.primary,
        child: transactions.when(
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: 6,
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: ShimmerListItem(),
            ),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (txs) {
            if (txs.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.receipt_long_outlined,
                title: AppStrings.noTransactions,
                subtitle: AppStrings.noTransactionsDesc,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSizes.md),
              itemCount: txs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, idx) => _TransactionCard(transaction: txs[idx]),
            );
          },
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primaryWithOpacity10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.transactionCode,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.formatDateTime(transaction.createdAt),
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPaymentColor(transaction.paymentMethod).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                        ),
                        child: Text(
                          _getPaymentLabel(transaction.paymentMethod),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getPaymentColor(transaction.paymentMethod),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${transaction.totalItems} item',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(transaction.total),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPaymentColor(String method) {
    return method == 'cash' ? AppColors.success : AppColors.info;
  }

  String _getPaymentLabel(String method) {
    return method == 'cash' ? 'Tunai' : 'QRIS';
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransactionDetailSheet(transaction: transaction),
    );
  }
}

class _TransactionDetailSheet extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionDetailSheet({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryWithOpacity10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.transactionCode,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                      Text(
                        DateFormatter.formatDateTime(transaction.createdAt),
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Item Pesanan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                  const SizedBox(height: 10),
                  ...transaction.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
                              Text(
                                '${item.quantity} x ${CurrencyFormatter.format(item.productPrice)}',
                                style: TextStyle(fontSize: 11, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(item.subtotal),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                      ],
                    ),
                  )),
                  const Divider(),
                  _DetailRow('Subtotal', CurrencyFormatter.format(transaction.subtotal), textSecondary, textPrimary),
                  if (transaction.discount > 0)
                    _DetailRow('Diskon', '- ${CurrencyFormatter.format(transaction.discount)}', textSecondary, AppColors.success),
                  _DetailRow('Total', CurrencyFormatter.format(transaction.total), textSecondary, AppColors.primary, isBold: true),
                  _DetailRow('Metode Bayar', transaction.paymentMethod == 'cash' ? 'Tunai' : 'QRIS', textSecondary, textPrimary),
                  _DetailRow('Dibayar', CurrencyFormatter.format(transaction.amountPaid), textSecondary, textPrimary),
                  if (transaction.changeAmount > 0)
                    _DetailRow('Kembalian', CurrencyFormatter.format(transaction.changeAmount), textSecondary, AppColors.success),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  final bool isBold;

  const _DetailRow(this.label, this.value, this.labelColor, this.valueColor, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: labelColor)),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
