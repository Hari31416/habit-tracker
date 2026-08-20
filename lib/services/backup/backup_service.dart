import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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
    bool compress = false,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final jsonString = await backupRepository.exportBackupJson(deviceId: deviceId);
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final extension = compress ? 'json.gz' : 'json';
      final mimeType = compress ? 'application/gzip' : 'application/json';
      final file = File('${tempDir.path}/phial_backup_$timestamp.$extension');

      if (compress) {
        final compressedBytes = gzip.encode(utf8.encode(jsonString));
        await file.writeAsBytes(compressedBytes);
      } else {
        await file.writeAsString(jsonString);
      }

      final result = await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType)],
        subject: 'Phial Habit Tracker Backup ($timestamp)',
        text: 'Phial Habit Tracker Backup',
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
    bool compress = false,
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
      final extension = compress ? 'json.gz' : 'json';
      final mimeType = compress ? 'application/gzip' : 'application/json';
      final file = File('${tempDir.path}/phial_backup_encrypted_$timestamp.$extension');

      if (compress) {
        final compressedBytes = gzip.encode(utf8.encode(encryptedJson));
        await file.writeAsBytes(compressedBytes);
      } else {
        await file.writeAsString(encryptedJson);
      }

      final result = await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType)],
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

  /// Opens native folder/file save dialog to save JSON backup directly to user-specified location.
  Future<String?> saveBackupJsonToStorage({
    String? deviceId,
    bool compress = false,
  }) async {
    try {
      final jsonString = await backupRepository.exportBackupJson(deviceId: deviceId);
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final extension = compress ? 'json.gz' : 'json';
      final bytes = compress
          ? Uint8List.fromList(gzip.encode(utf8.encode(jsonString)))
          : Uint8List.fromList(utf8.encode(jsonString));

      return await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup File',
        fileName: 'phial_backup_$timestamp.$extension',
        type: FileType.custom,
        allowedExtensions: [extension, 'gz', 'json'],
        bytes: bytes,
      );
    } catch (e, stack) {
      // ignore: avoid_print
      print('saveBackupJsonToStorage error: $e\n$stack');
      return null;
    }
  }

  /// Opens native folder/file save dialog to save encrypted backup directly to user-specified location.
  Future<String?> saveEncryptedBackupJsonToStorage({
    required String password,
    String? deviceId,
    bool compress = false,
  }) async {
    try {
      final plaintextJson = await backupRepository.exportBackupJson(deviceId: deviceId);
      final encryptedJson = await BackupEncryptionEngine.encrypt(
        plaintextJson: plaintextJson,
        password: password,
      );
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final extension = compress ? 'json.gz' : 'json';
      final bytes = compress
          ? Uint8List.fromList(gzip.encode(utf8.encode(encryptedJson)))
          : Uint8List.fromList(utf8.encode(encryptedJson));

      return await FilePicker.platform.saveFile(
        dialogTitle: 'Save Encrypted Backup File',
        fileName: 'phial_backup_encrypted_$timestamp.$extension',
        type: FileType.custom,
        allowedExtensions: [extension, 'gz', 'json'],
        bytes: bytes,
      );
    } catch (e, stack) {
      // ignore: avoid_print
      print('saveEncryptedBackupJsonToStorage error: $e\n$stack');
      return null;
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

  /// Opens native file picker to select a backup JSON or compressed GZ file. Returns file content string.
  Future<String?> pickBackupFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'gz'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();

        // Check if gzip compressed (magic bytes 0x1F, 0x8B)
        if (bytes.length >= 2 && bytes[0] == 0x1F && bytes[1] == 0x8B) {
          final decompressedBytes = gzip.decode(bytes);
          return utf8.decode(decompressedBytes);
        } else {
          return utf8.decode(bytes);
        }
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
