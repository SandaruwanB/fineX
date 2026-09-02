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
    static Future<bool> exportBackup(BuildContext context) async {
        final box = context.findRenderObject() as RenderBox?;
        try {
            final data = await DbHelper.exportAllData();
            final jsonString = jsonEncode(data);
            final jsonBytes = utf8.encode(jsonString);

            final archive = Archive();
            archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));

            final zipBytes = ZipEncoder().encode(archive);
            if (zipBytes == null) return false;

            final tempDir = await getTemporaryDirectory();
            final backupFile = File('${tempDir.path}/finex_backup.zip');
            await backupFile.writeAsBytes(zipBytes);

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


    static Future<bool> importBackup(BuildContext context, WidgetRef ref) async {
        try {
            final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['zip'],
            );

            if (result == null || result.files.single.path == null) {
                return false; 
            }

            final file = File(result.files.single.path!);
            final bytes = await file.readAsBytes();

            // decode the zip
            final archive = ZipDecoder().decodeBytes(bytes);

            // find and extract data.json
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

            await DbHelper.restoreAllData(dataMap);

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
