import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/cash_register_model.dart';
import '../utils/formatters.dart';

class PdfReportService {
  static Future<String?> generateAndSaveReport(List<TransactionModel> transactions) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildHeader('Riwayat Transaksi'),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            _buildSalesSummary(transactions),
            pw.SizedBox(height: 20),
            _buildPaymentMethodsSummary(transactions),
          ],
        ),
      );

      return await _savePdf(pdf, 'Riwayat_Transaksi_${DateTime.now().millisecondsSinceEpoch}');
    } catch (e) {
      throw Exception('Gagal membuat PDF: $e');
    }
  }

  static Future<String?> generateComprehensiveReport({
    required List<TransactionModel> transactions,
    required List<Map<String, dynamic>> products,
    required Map<String, dynamic> profitLoss,
    required List<Map<String, dynamic>> chartData,
    CashRegisterSession? session,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final pdf = pw.Document();

      // Laporan Terpadu (Satu aliran dokumen)
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildHeader('Laporan Keuangan Terpadu'),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            if (session != null) ...[
              pw.Text('Informasi Sesi Kasir', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _buildSessionSummary(session),
              pw.SizedBox(height: 20),
            ],
            pw.Text('Ringkasan Penjualan', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            _buildSalesSummary(transactions),
            pw.SizedBox(height: 20),
            pw.Text('Metode Pembayaran', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            _buildPaymentMethodsSummary(transactions),
            
            pw.SizedBox(height: 30),
            
            pw.Text('Laporan Laba Rugi', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            _buildProfitLossStatement(profitLoss),

            pw.SizedBox(height: 30),

            pw.Text('Laporan Produk Terjual', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            _buildProductsTable(products),
          ],
        ),
      );

      return await _savePdf(pdf, 'Laporan_Keuangan_${DateFormatter.formatDate(startDate).replaceAll(' ', '_')}');
    } catch (e) {
      throw Exception('Gagal membuat PDF: $e');
    }
  }

  static pw.Widget _buildHeader(String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ALFlow Kasir',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          subtitle,
          style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Tanggal Cetak: ${DateFormatter.formatDateTime(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget _buildSessionSummary(CashRegisterSession session) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        children: [
          _summaryRow('Status Sesi', session.isOpen ? 'BUKA' : 'TUTUP', isBold: true, color: session.isOpen ? PdfColors.green700 : PdfColors.red700),
          _summaryRow('Waktu Buka', DateFormatter.formatDateTime(session.openedAt)),
          if (session.closedAt != null) _summaryRow('Waktu Tutup', DateFormatter.formatDateTime(session.closedAt!)),
          pw.Divider(),
          _summaryRow('Modal Awal', CurrencyFormatter.format(session.openingAmount)),
          _summaryRow('Penjualan Tunai', CurrencyFormatter.format(session.totalCashSales)),
          _summaryRow('Total Kas Seharusnya', CurrencyFormatter.format(session.calculatedExpectedAmount), isBold: true),
          if (session.closingAmount != null) ...[
            pw.Divider(),
            _summaryRow('Uang Fisik Aktual', CurrencyFormatter.format(session.closingAmount!), isBold: true),
            _summaryRow(
              'Selisih', 
              CurrencyFormatter.format(session.difference ?? 0), 
              isBold: true, 
              color: (session.difference ?? 0) < 0 ? PdfColors.red700 : ((session.difference ?? 0) > 0 ? PdfColors.green700 : PdfColors.black)
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildSalesSummary(List<TransactionModel> transactions) {
    double totalRevenue = 0;
    double totalDiscount = 0;
    double totalNet = 0;
    int totalItems = 0;

    for (var tx in transactions) {
      totalRevenue += tx.subtotal;
      totalDiscount += tx.discount;
      totalNet += tx.total;
      totalItems += tx.totalItems;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _summaryRow('Total Pendapatan', CurrencyFormatter.format(totalRevenue)),
              _summaryRow('Total Diskon', '- ${CurrencyFormatter.format(totalDiscount)}', color: PdfColors.red600),
              _summaryRow('Pendapatan Bersih', CurrencyFormatter.format(totalNet), isBold: true, color: PdfColors.green700),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _summaryRow('Total Transaksi', '${transactions.length}'),
              _summaryRow('Total Item Terjual', '$totalItems'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentMethodsSummary(List<TransactionModel> transactions) {
    double cash = 0;
    double qris = 0;

    for (var tx in transactions) {
      if (tx.paymentMethod == 'cash') {
        cash += tx.total;
      } else {
        qris += tx.total;
      }
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _summaryRow('Tunai (Cash)', CurrencyFormatter.format(cash), isBold: true),
          _summaryRow('Digital (QRIS)', CurrencyFormatter.format(qris), isBold: true),
        ],
      ),
    );
  }

  static pw.Widget _buildProductsTable(List<Map<String, dynamic>> products) {
    if (products.isEmpty) {
      return pw.Text('Belum ada data penjualan produk.');
    }

    return pw.TableHelper.fromTextArray(
      context: null,
      headers: ['No', 'Nama Produk', 'Terjual (Qty)', 'Pendapatan', 'Laba'],
      data: List<List<dynamic>>.generate(
        products.length,
        (index) {
          final item = products[index];
          return [
            (index + 1).toString(),
            item['product_name'],
            item['total_qty'].toString(),
            CurrencyFormatter.format(item['total_revenue'] ?? 0),
            CurrencyFormatter.format(item['total_profit'] ?? 0),
          ];
        },
      ),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: {
        0: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildProfitLossStatement(Map<String, dynamic> plData) {
    final revenue = plData['revenue'] as double;
    final discount = plData['discount'] as double;
    final cogs = plData['cogs'] as double;
    final grossProfit = plData['gross_profit'] as double;
    final operationalCosts = plData['operational_costs'] as double;
    final netProfit = plData['net_profit'] as double;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Pendapatan', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 8),
          _summaryRow('Penjualan Kotor', CurrencyFormatter.format(revenue)),
          _summaryRow('Diskon', '( ${CurrencyFormatter.format(discount)} )', color: PdfColors.red700),
          pw.Divider(),
          _summaryRow('Penjualan Bersih', CurrencyFormatter.format(revenue - discount), isBold: true),
          
          pw.SizedBox(height: 20),
          pw.Text('Harga Pokok Penjualan (HPP)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 8),
          _summaryRow('HPP / Modal Barang', '( ${CurrencyFormatter.format(cogs)} )', color: PdfColors.red700),
          pw.Divider(),
          _summaryRow('Laba Kotor', CurrencyFormatter.format(grossProfit), isBold: true, color: PdfColors.blue800),

          pw.SizedBox(height: 20),
          pw.Text('Biaya Operasional', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 8),
          _summaryRow('Total Biaya', '( ${CurrencyFormatter.format(operationalCosts)} )', color: PdfColors.red700),
          pw.Divider(thickness: 2),
          _summaryRow('Laba Bersih', CurrencyFormatter.format(netProfit), isBold: true, color: netProfit >= 0 ? PdfColors.green700 : PdfColors.red700),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Text(
        'Halaman ${context.pageNumber} dari ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value, {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 12, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static Future<String?> _savePdf(pw.Document pdf, [String? prefix]) async {
    Directory? exportDir;
    if (Platform.isAndroid) {
      exportDir = Directory('/storage/emulated/0/Documents/laporan keuangan');
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      exportDir = Directory('${docDir.path}/laporan keuangan');
    }

    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final name = prefix ?? 'Laporan_Transaksi_${DateTime.now().millisecondsSinceEpoch}';
    final file = File('${exportDir.path}/$name.pdf');
    
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}
