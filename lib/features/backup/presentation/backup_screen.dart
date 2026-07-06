import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  String? _lastBackupDate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.backupRestore),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
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
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Backup Data',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          _lastBackupDate != null
                              ? 'Terakhir backup: $_lastBackupDate'
                              : 'Backup data Anda secara berkala',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            // Backup section
            Text(
              AppStrings.exportData,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Ekspor database ke file untuk disimpan di perangkat Anda',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            const SizedBox(height: AppSizes.md),

            _ActionCard(
              icon: Icons.file_download_rounded,
              iconColor: AppColors.success,
              title: 'Export Database',
              subtitle: 'Simpan file database (.db)',
              isLoading: _isExporting,
              onTap: _exportDatabase,
              isDark: isDark,
              cardColor: cardColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),

            const SizedBox(height: AppSizes.lg),

            Text(
              AppStrings.importData,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
            ),
            const SizedBox(height: AppSizes.sm),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Import akan menggantikan semua data yang ada saat ini',
                      style: TextStyle(fontSize: 12, color: AppColors.warning.withValues(alpha: 0.9)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            _ActionCard(
              icon: Icons.file_upload_rounded,
              iconColor: AppColors.warning,
              title: 'Import Database',
              subtitle: 'Muat file database (.db)',
              isLoading: _isImporting,
              onTap: _importDatabase,
              isDark: isDark,
              cardColor: cardColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),

            const SizedBox(height: AppSizes.xl),

            // Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tips_and_updates_rounded, color: AppColors.info, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Tips Backup',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...[
                    '• Lakukan backup minimal seminggu sekali',
                    '• Simpan backup di Google Drive / cloud',
                    '• Backup sebelum melakukan update aplikasi',
                  ].map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(tip, style: TextStyle(fontSize: 12, color: textSecondary, height: 1.5)),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Future<void> _exportDatabase() async {
    setState(() => _isExporting = true);
    try {
      if (Platform.isAndroid) {
        if (await Permission.manageExternalStorage.status != PermissionStatus.granted) {
          await Permission.manageExternalStorage.request();
        }
        if (await Permission.storage.status != PermissionStatus.granted) {
          await Permission.storage.request();
        }
      }

      final dbPath = await getDatabasesPath();
      final sourceFile = File('$dbPath/alflow_pos.db');

      if (!await sourceFile.exists()) {
        _showSnack('Database tidak ditemukan', AppColors.error);
        return;
      }

      Directory? backupDir;
      if (Platform.isAndroid) {
        backupDir = Directory('/storage/emulated/0/Download/database ALFlow kasir');
      } else {
        final docDir = await getApplicationDocumentsDirectory();
        backupDir = Directory('${docDir.path}/database ALFlow kasir');
      }

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final now = DateTime.now();
      final dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      final day = dayNames[now.weekday - 1];
      final date = now.day.toString().padLeft(2, '0');
      final monthNames = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
      final month = monthNames[now.month - 1];
      final year = now.year.toString();
      final time = '${now.hour.toString().padLeft(2, '0')}_${now.minute.toString().padLeft(2, '0')}';

      final filename = 'backup DB ($day, $date, $month, $year, $time).db';
      final destFile = File('${backupDir.path}/$filename');

      await sourceFile.copy(destFile.path);

      setState(() => _lastBackupDate = DateFormatter.formatDateTime(now));
      _showSnack('Backup tersimpan di: ${backupDir.path}', AppColors.success);
    } catch (e) {
      _showSnack('Error: $e', AppColors.error);
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _importDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Import'),
        content: const Text(
          'Import akan MENGGANTIKAN semua data yang ada saat ini. Pastikan Anda sudah backup data terlebih dahulu.\n\nLanjutkan?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.white),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await FilePicker.pickFiles(type: FileType.any);

      if (result != null && result.files.single.path != null) {
        setState(() => _isImporting = true);
        
        final pickedFile = File(result.files.single.path!);
        
        // Validate if it's a db file
        if (!pickedFile.path.endsWith('.db')) {
           _showSnack('File tidak valid. Harap pilih file backup .db', AppColors.error);
           setState(() => _isImporting = false);
           return;
        }

        // Close current database
        await DatabaseHelper().closeDatabase();

        // Overwrite the database file
        final dbPath = await getDatabasesPath();
        final targetFile = File('$dbPath/alflow_pos.db');
        await pickedFile.copy(targetFile.path);

        _showSnack('Import berhasil! Data telah dipulihkan.', AppColors.success);
      }
    } catch (e) {
      _showSnack('Gagal mengimpor database: $e', AppColors.error);
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback onTap;
  final bool isDark;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.onTap,
    required this.isDark,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                        ),
                      )
                    : Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
