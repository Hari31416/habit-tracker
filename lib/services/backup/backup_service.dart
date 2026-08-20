import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flutter/widgets.dart';

import '../../domain/repositories/backup_repository.dart';
import '../../domain/sync/backup_encryption_engine.dart';
import '../../domain/sync/sync_merge_engine.dart';

class BackupService {
  final BackupRepository backupRepository;

  BackupService({required this.backupRepository});

  /// Exports full JSON backup and opens native OS Share Sheet.
  Future<bool> exportAndShareBackupJson({
    String? deviceId,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final jsonString = await backupRepository.exportBackupJson(deviceId: deviceId);
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${tempDir.path}/phial_backup_$timestamp.json');
      await file.writeAsString(jsonString);

      final result = await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Phial Habit Tracker Backup ($timestamp)',
        text: 'Phial Habit Tracker JSON Backup',
        sharePositionOrigin: sharePositionOrigin,
      );

      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (e, stack) {
      // ignore: avoid_print
      print('exportAndShareBackupJson error: $e\n$stack');
      return false;
    }
  }

  /// Exports encrypted JSON backup with password protection and opens native OS Share Sheet.
  Future<bool> exportAndShareEncryptedBackupJson({
    required String password,
    String? deviceId,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final plaintextJson = await backupRepository.exportBackupJson(deviceId: deviceId);
      final encryptedJson = await BackupEncryptionEngine.encrypt(
        plaintextJson: plaintextJson,
        password: password,
      );
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${tempDir.path}/phial_backup_encrypted_$timestamp.json');
      await file.writeAsString(encryptedJson);

      final result = await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Phial Habit Tracker Encrypted Backup ($timestamp)',
        text: 'Phial Habit Tracker Encrypted Backup (Password Protected)',
        sharePositionOrigin: sharePositionOrigin,
      );

      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (e, stack) {
      // ignore: avoid_print
      print('exportAndShareEncryptedBackupJson error: $e\n$stack');
      return false;
    }
  }

  /// Exports habits & logs CSV files and opens native OS Share Sheet.
  Future<bool> exportAndShareCsv({Rect? sharePositionOrigin}) async {
    try {
      final habitsCsv = await backupRepository.exportHabitsCsv();
      final logsCsv = await backupRepository.exportLogsCsv();
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      final habitsFile = File('${tempDir.path}/habits_$timestamp.csv');
      await habitsFile.writeAsString(habitsCsv);

      final logsFile = File('${tempDir.path}/habit_logs_$timestamp.csv');
      await logsFile.writeAsString(logsCsv);

      final result = await Share.shareXFiles(
        [
          XFile(habitsFile.path, mimeType: 'text/csv'),
          XFile(logsFile.path, mimeType: 'text/csv'),
        ],
        subject: 'Phial Habit Tracker CSV Export ($timestamp)',
        text: 'Phial Habits & Logs CSV Export',
        sharePositionOrigin: sharePositionOrigin,
      );

      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (e, stack) {
      // ignore: avoid_print
      print('exportAndShareCsv error: $e\n$stack');
      return false;
    }
  }

  /// Opens native file picker to select a backup JSON file. Returns file content string.
  Future<String?> pickBackupFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        return await file.readAsString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Previews the merge results against the local database.
  Future<MergeResult> previewImport(String jsonString) {
    return backupRepository.previewImport(jsonString);
  }

  /// Applies import in the given mode (Merge or Overwrite).
  Future<MergeStats> executeImport(String jsonString, {required ImportMode mode}) {
    return backupRepository.executeImport(jsonString, mode: mode);
  }
}
