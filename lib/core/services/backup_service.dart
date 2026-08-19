import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'db_helper.dart';
import '../../features/accounts/accounts_provider.dart';
import '../../features/categories/categories_provider.dart';

class BackupService {
  /// Exports all SQLite records, encodes them to JSON inside a Zip archive,
  /// and displays the platform share sheet to let the user save the `.zip` file.
  static Future<bool> exportBackup(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    try {
      // 1. Retrieve all database tables
      final data = await DbHelper.exportAllData();
      final jsonString = jsonEncode(data);
      final jsonBytes = utf8.encode(jsonString);

      // 2. Build Zip Archive in memory
      final archive = Archive();
      archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));

      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) return false;

      // 3. Write Zip Archive to temporary directory
      final tempDir = await getTemporaryDirectory();
      final backupFile = File('${tempDir.path}/finex_backup.zip');
      await backupFile.writeAsBytes(zipBytes);

      // 4. Trigger Native Share Sheet
      final shareResult = await Share.shareXFiles(
        [XFile(backupFile.path, mimeType: 'application/zip')],
        subject: 'fineX Financial Backup',
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );

      return shareResult.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint('Backup export failed: $e');
      return false;
    }
  }

  /// Opens the file picker for the user to select a backup `.zip` file,
  /// extracts `data.json` inside it, decrypts/parses, updates SQLite tables,
  /// and updates Riverpod provider states.
  static Future<bool> importBackup(BuildContext context, WidgetRef ref) async {
    try {
      // 1. Pick ZIP file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.single.path == null) {
        return false; // User cancelled
      }

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();

      // 2. Decode the Zip archive
      final archive = ZipDecoder().decodeBytes(bytes);

      // 3. Find and extract data.json
      final dataJsonFile = archive.findFile('data.json');
      if (dataJsonFile == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid backup file: data.json not found.')),
          );
        }
        return false;
      }

      final contentString = utf8.decode(dataJsonFile.content as List<int>);
      final dataMap = jsonDecode(contentString) as Map<String, dynamic>;

      // 4. Restore tables in SQLite transaction
      await DbHelper.restoreAllData(dataMap);

      // 5. Reload Riverpod providers to update UI immediately
      await ref.read(accountsProvider.notifier).loadAccounts();
      await ref.read(categoriesProvider.notifier).loadCategories();

      return true;
    } catch (e) {
      debugPrint('Backup import failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error restoring backup: $e')),
        );
      }
      return false;
    }
  }
}
