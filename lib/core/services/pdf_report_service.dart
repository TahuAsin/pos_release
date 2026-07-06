import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../data/models/transaction_model.dart';
import '../utils/formatters.dart';

class PdfReportService {
  static Future<String?> generateAndSaveReport(List<TransactionModel> transactions) async {
    try {
      final pdf = pw.Document();

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

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildHeader(),
          build: (context) => [
            _buildSummary(totalRevenue, totalDiscount, totalNet, transactions.length, totalItems),
            pw.SizedBox(height: 20),
            _buildTransactionTable(transactions),
          ],
          footer: (context) => _buildFooter(context),
        ),
      );

      return await _savePdf(pdf);
    } catch (e) {
      throw Exception('Gagal membuat PDF: $e');
    }
  }

  static pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ALFlow Kasir',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Laporan Keuangan',
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

  static pw.Widget _buildSummary(double gross, double discount, double net, int totalTx, int items) {
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
              pw.Text('Ringkasan', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              _summaryRow('Total Pendapatan', CurrencyFormatter.format(gross)),
              _summaryRow('Total Diskon', '- ${CurrencyFormatter.format(discount)}', color: PdfColors.red600),
              _summaryRow('Pendapatan Bersih', CurrencyFormatter.format(net), isBold: true, color: PdfColors.green700),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.SizedBox(height: 22),
              _summaryRow('Total Transaksi', '$totalTx'),
              _summaryRow('Item Terjual', '$items'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value, {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('$label: ', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTransactionTable(List<TransactionModel> transactions) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Rincian Transaksi', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Waktu', 'Kode', 'Metode Bayar', 'Item', 'Total'],
          data: transactions.map((tx) => [
            DateFormatter.formatDateTime(tx.createdAt),
            tx.transactionCode,
            tx.paymentMethod == 'cash' ? 'Tunai' : 'QRIS',
            '${tx.totalItems}',
            CurrencyFormatter.format(tx.total),
          ]).toList(),
          border: pw.TableBorder.all(color: PdfColors.grey300),
          headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.center,
            3: pw.Alignment.center,
            4: pw.Alignment.centerRight,
          },
          cellPadding: const pw.EdgeInsets.all(6),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Halaman ${context.pageNumber} dari ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
    );
  }

  static Future<String?> _savePdf(pw.Document pdf) async {
    try {
      Directory? backupDir;
      if (Platform.isAndroid) {
        if (await Permission.manageExternalStorage.status != PermissionStatus.granted) {
          await Permission.manageExternalStorage.request();
        }
        if (await Permission.storage.status != PermissionStatus.granted) {
          await Permission.storage.request();
        }
        backupDir = Directory('/storage/emulated/0/Download/database ALFlow kasir');
      } else {
        final docDir = await getApplicationDocumentsDirectory();
        backupDir = Directory('${docDir.path}/database ALFlow kasir');
      }

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final String now = DateTime.now().toIso8601String().replaceAll(':', '_').split('.').first;
      final String fileName = 'Laporan_Keuangan_ALFlow_$now.pdf';
      final File file = File('${backupDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      throw Exception('Gagal menyimpan file PDF: $e');
    }
  }
}
