import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/di/providers.dart';
import 'package:habit_tracker/domain/models/sync/sync_envelope.dart';
import 'package:habit_tracker/domain/repositories/backup_repository.dart';
import 'package:habit_tracker/domain/sync/sync_merge_engine.dart';
import 'package:habit_tracker/services/backup/backup_service.dart';
import 'package:habit_tracker/ui/settings/backup_settings_bottom_sheet.dart';

class FakeBackupRepository implements BackupRepository {
  @override
  Future<SyncEnvelope> createSnapshot({String? deviceId}) async {
    return SyncEnvelope(
      appVersion: '0.8.1',
      exportedAt: DateTime.utc(2026, 8, 20),
      deviceId: deviceId ?? 'fake_device',
      data: const SyncDataPayload(),
    );
  }

  @override
  Future<String> exportBackupJson({String? deviceId}) async {
    return '{"schemaVersion": 1, "data": {}}';
  }

  @override
  Future<String> exportHabitsCsv() async => 'id,title,category\n';

  @override
  Future<String> exportLogsCsv() async => 'id,habitId,date\n';

  @override
  Future<MergeStats> executeImport(String jsonString, {required ImportMode mode}) async {
    return const MergeStats(habitsAdded: 2, logsMerged: 10, totalXp: 200, level: 3);
  }

  @override
  Future<MergeResult> previewImport(String jsonString) async {
    return const MergeResult(
      mergedPayload: SyncDataPayload(),
      stats: MergeStats(habitsAdded: 2, logsMerged: 10, totalXp: 200, level: 3),
    );
  }
}

void main() {
  testWidgets('BackupSettingsBottomSheet renders options and handles actions', (tester) async {
    final fakeRepo = FakeBackupRepository();
    final fakeService = BackupService(backupRepository: fakeRepo);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupRepositoryProvider.overrideWithValue(fakeRepo),
          backupServiceProvider.overrideWithValue(fakeService),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: BackupSettingsBottomSheet(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Data & Backup'), findsOneWidget);
    expect(find.text('Export Backup (JSON)'), findsOneWidget);
    expect(find.text('Export Encrypted Backup'), findsOneWidget);
    expect(find.text('Import Backup (JSON)'), findsOneWidget);
    expect(find.text('Export Spreadsheets (CSV)'), findsOneWidget);

    // Tap Export Encrypted Backup to open password dialog
    await tester.tap(find.text('Export Encrypted Backup'));
    await tester.pumpAndSettle();

    expect(find.text('Encrypted Backup'), findsOneWidget);
    expect(find.text('Generate Random Passkey'), findsOneWidget);
    expect(find.text('Passkey / Password'), findsOneWidget);
    expect(find.text('Confirm Passkey'), findsOneWidget);
    expect(find.text('Encrypt & Export'), findsOneWidget);
  });
}
