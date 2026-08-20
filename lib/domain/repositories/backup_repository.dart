import '../models/sync/sync_envelope.dart';
import '../sync/sync_merge_engine.dart';

enum ImportMode {
  /// Deterministic 2-way merge preserving natural keys and LWW. Safe for sync.
  merge,

  /// Clean device restore (wipes existing tables and loads exact snapshot). Local recovery only.
  overwrite,
}

abstract class BackupRepository {
  /// Generates a complete relational sync snapshot of the current database.
  Future<SyncEnvelope> createSnapshot({String? deviceId});

  /// Exports formatted JSON string of the current state.
  Future<String> exportBackupJson({String? deviceId});

  /// Previews the merge results against the current local state without writing.
  Future<MergeResult> previewImport(String jsonString);

  /// Executes import in either Merge or Clean Replace mode inside an atomic database transaction.
  Future<MergeStats> executeImport(String jsonString, {required ImportMode mode});

  /// Exports habits data in CSV format.
  Future<String> exportHabitsCsv();

  /// Exports habit check-in logs in CSV format.
  Future<String> exportLogsCsv();
}
