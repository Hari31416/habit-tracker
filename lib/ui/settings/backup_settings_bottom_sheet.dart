import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/preferences/theme_preferences.dart';
import '../../di/providers.dart';
import '../../domain/repositories/backup_repository.dart';
import '../../domain/sync/backup_encryption_engine.dart';
import '../../domain/sync/sync_merge_engine.dart';
import '../common/haptics_helper.dart';
import 'passkey_input_widget.dart';

class BackupSettingsBottomSheet extends ConsumerStatefulWidget {
  const BackupSettingsBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BackupSettingsBottomSheet(),
    );
  }

  @override
  ConsumerState<BackupSettingsBottomSheet> createState() =>
      _BackupSettingsBottomSheetState();
}

class _BackupSettingsBottomSheetState
    extends ConsumerState<BackupSettingsBottomSheet> {
  bool _isLoading = false;
  String? _statusMessage;

  void _showError(String message) {
    HapticsHelper.performHeavyConfirmationHaptic();
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showExportOptionsDialog({required bool isEncrypted, String? password}) {
    final theme = Theme.of(context);
    bool compress = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEncrypted ? 'Export Encrypted Backup' : 'Export JSON Backup',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      secondary: const Icon(Icons.compress_outlined),
                      title: const Text('Compress Backup (.json.gz)'),
                      subtitle: const Text('Reduces file size by up to 90%'),
                      value: compress,
                      onChanged: (val) {
                        setSheetState(() {
                          compress = val;
                        });
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.folder_open_outlined),
                      title: Text(compress ? 'Save to Storage (.json.gz)' : 'Save to Storage (.json)'),
                      subtitle: const Text('Save directly to Downloads, Documents, or SD Card'),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        if (isEncrypted && password != null) {
                          _handleSaveEncryptedJsonToStorage(password, compress: compress);
                        } else {
                          _handleSaveJsonToStorage(compress: compress);
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.share_outlined),
                      title: Text(compress ? 'Share via Apps (.json.gz)' : 'Share via Apps (.json)'),
                      subtitle: const Text('Send to Google Drive, Gmail, Quick Share, etc.'),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        if (isEncrypted && password != null) {
                          _handleExportEncryptedJson(password, compress: compress);
                        } else {
                          _handleExportJson(compress: compress);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleSaveJsonToStorage({bool compress = false}) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Opening storage picker...';
    });

    final service = ref.read(backupServiceProvider);
    final savedPath = await service.saveBackupJsonToStorage(compress: compress);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });
      if (savedPath != null) {
        HapticsHelper.performLightHaptic();
        _showSuccess(compress ? 'Compressed backup (.json.gz) saved' : 'Backup saved to storage');
      }
    }
  }

  Future<void> _handleSaveEncryptedJsonToStorage(String password, {bool compress = false}) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Encrypting & opening storage picker...';
    });

    final service = ref.read(backupServiceProvider);
    final savedPath = await service.saveEncryptedBackupJsonToStorage(
      password: password,
      compress: compress,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });
      if (savedPath != null) {
        HapticsHelper.performLightHaptic();
        _showSuccess(compress ? 'Compressed encrypted backup saved' : 'Encrypted backup saved to storage');
      }
    }
  }

  Future<void> _handleExportJson({bool compress = false}) async {
    setState(() {
      _isLoading = true;
      _statusMessage = compress ? 'Compressing JSON backup (.json.gz)...' : 'Generating JSON backup...';
    });

    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    final service = ref.read(backupServiceProvider);
    final success = await service.exportAndShareBackupJson(
      compress: compress,
      sharePositionOrigin: origin,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });
      if (success) {
        HapticsHelper.performLightHaptic();
        _showSuccess(compress ? 'Compressed backup exported successfully' : 'Backup exported successfully');
      } else {
        _showError('Failed to export backup');
      }
    }
  }

  void _showEncryptedExportDialog() {
    final theme = Theme.of(context);
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscure = true;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.lock_outline, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 8),
                  const Text('Encrypted Backup'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Protect your habits, notes, and logs with AES-256 zero-knowledge encryption.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.key_outlined, size: 18),
                      label: const Text('Generate Random Passkey'),
                      onPressed: () {
                        final key = BackupEncryptionEngine.generatePasskey();
                        passwordController.text = key;
                        confirmController.text = key;
                        Clipboard.setData(ClipboardData(text: key));
                        setDialogState(() {
                          obscure = false;
                          errorText = null;
                        });
                        HapticsHelper.performLightHaptic();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passkey generated & copied to clipboard!'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: 'Passkey / Password',
                        prefixIcon: const Icon(Icons.password_outlined),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (passwordController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.copy_outlined, size: 20),
                                tooltip: 'Copy',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: passwordController.text));
                                  HapticsHelper.performLightHaptic();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Passkey copied to clipboard'),
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            IconButton(
                              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                              onPressed: () {
                                setDialogState(() {
                                  obscure = !obscure;
                                });
                              },
                            ),
                          ],
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmController,
                      obscureText: obscure,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Passkey',
                        prefixIcon: Icon(Icons.check_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorText!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Warning: If you lose this passkey, this backup cannot be decrypted or restored.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.lock, size: 18),
                  label: const Text('Export...'),
                  onPressed: () {
                    final pass = passwordController.text.trim();
                    final conf = confirmController.text.trim();

                    if (pass.isEmpty) {
                      setDialogState(() {
                        errorText = 'Please enter or generate a passkey';
                      });
                      return;
                    }
                    if (pass.length < 6) {
                      setDialogState(() {
                        errorText = 'Passkey must be at least 6 characters';
                      });
                      return;
                    }
                    if (pass != conf) {
                      setDialogState(() {
                        errorText = 'Passkeys do not match';
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop();
                    _showExportOptionsDialog(isEncrypted: true, password: pass);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleExportEncryptedJson(String password, {bool compress = false}) async {
    setState(() {
      _isLoading = true;
      _statusMessage = compress
          ? 'Compressing & encrypting backup (AES-256)...'
          : 'Encrypting backup (AES-256)...';
    });

    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    final service = ref.read(backupServiceProvider);
    final success = await service.exportAndShareEncryptedBackupJson(
      password: password,
      compress: compress,
      sharePositionOrigin: origin,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });
      if (success) {
        HapticsHelper.performLightHaptic();
        _showSuccess(compress ? 'Compressed encrypted backup exported' : 'Encrypted backup exported successfully');
      } else {
        _showError('Failed to export encrypted backup');
      }
    }
  }

  Future<void> _handleExportCsv() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Exporting CSV data...';
    });

    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    final service = ref.read(backupServiceProvider);
    final success = await service.exportAndShareCsv(sharePositionOrigin: origin);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });
      if (success) {
        HapticsHelper.performLightHaptic();
        _showSuccess('CSV data exported successfully');
      } else {
        _showError('Failed to export CSV');
      }
    }
  }

  Future<void> _handleImportJson() async {
    final service = ref.read(backupServiceProvider);
    final rawFileString = await service.pickBackupFile();

    if (rawFileString == null || rawFileString.isEmpty) {
      return;
    }

    if (BackupEncryptionEngine.isEncrypted(rawFileString)) {
      _showDecryptionPasswordPrompt(rawFileString);
    } else {
      _processPlaintextBackup(rawFileString);
    }
  }

  void _showDecryptionPasswordPrompt(String encryptedJson) {
    final theme = Theme.of(context);
    final passwordController = TextEditingController();
    bool obscure = false;
    bool isDecrypting = false;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: !isDecrypting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.lock, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 8),
                  const Text('Encrypted Backup'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This backup is protected with AES-256 encryption. Enter the 16-character passkey to unlock it.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Passkey (4×4 Code)',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              icon: const Icon(Icons.paste_outlined, size: 16),
                              label: const Text('Paste'),
                              onPressed: isDecrypting
                                  ? null
                                  : () async {
                                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                                      if (data?.text != null && data!.text!.isNotEmpty) {
                                        passwordController.text = data.text!;
                                        setDialogState(() {
                                          errorText = null;
                                        });
                                        HapticsHelper.performLightHaptic();
                                      }
                                    },
                            ),
                            IconButton(
                              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                              tooltip: obscure ? 'Show' : 'Hide',
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                setDialogState(() {
                                  obscure = !obscure;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    PasskeyInputWidget(
                      controller: passwordController,
                      obscureText: obscure,
                      enabled: !isDecrypting,
                      errorText: errorText,
                      onChanged: (_) {
                        if (errorText != null) {
                          setDialogState(() {
                            errorText = null;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDecrypting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  icon: isDecrypting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.lock_open, size: 18),
                  label: Text(isDecrypting ? 'Decrypting...' : 'Unlock'),
                  onPressed: isDecrypting
                      ? null
                      : () async {
                          final pass = passwordController.text.trim();
                          if (pass.isEmpty) {
                            setDialogState(() {
                              errorText = 'Please enter your passkey';
                            });
                            return;
                          }

                          setDialogState(() {
                            isDecrypting = true;
                            errorText = null;
                          });

                          try {
                            final decryptedJson = await BackupEncryptionEngine.decrypt(
                              encryptedEnvelopeJson: encryptedJson,
                              password: pass,
                            );

                            if (!dialogContext.mounted || !mounted) return;
                            Navigator.of(dialogContext).pop();
                            await _processPlaintextBackup(decryptedJson);
                          } on InvalidPasswordOrCorruptedException {
                            HapticsHelper.performHeavyConfirmationHaptic();
                            setDialogState(() {
                              isDecrypting = false;
                              errorText = 'Incorrect passkey. Please check and try again.';
                            });
                          } catch (e) {
                            HapticsHelper.performHeavyConfirmationHaptic();
                            setDialogState(() {
                              isDecrypting = false;
                              errorText = 'Decryption failed: Corrupted or invalid backup.';
                            });
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _processPlaintextBackup(String jsonString) async {
    final service = ref.read(backupServiceProvider);

    setState(() {
      _isLoading = true;
      _statusMessage = 'Analyzing backup file...';
    });

    try {
      final preview = await service.previewImport(jsonString);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });

      _showImportConfirmationDialog(jsonString, preview);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = null;
        });
        _showError('Invalid or corrupted backup file');
      }
    }
  }

  void _showImportConfirmationDialog(
    String jsonString,
    MergeResult preview,
  ) {
    final theme = Theme.of(context);
    final stats = preview.stats;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Import Backup'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Backup Contents:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(
                        Icons.check_circle_outline,
                        'Habits Added/Updated',
                        '+${stats.habitsAdded} added, ${stats.habitsUpdated} updated',
                        theme,
                      ),
                      const SizedBox(height: 6),
                      _buildSummaryRow(
                        Icons.history,
                        'Logs Merged',
                        '${stats.logsMerged} entries',
                        theme,
                      ),
                      const SizedBox(height: 6),
                      _buildSummaryRow(
                        Icons.shield_outlined,
                        'Shields Merged',
                        '${stats.shieldsMerged} shields',
                        theme,
                      ),
                      const SizedBox(height: 6),
                      _buildSummaryRow(
                        Icons.star_outline,
                        'Progress After Merge',
                        'Level ${stats.level} (${NumberFormat.compact().format(stats.totalXp)} XP)',
                        theme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select import mode:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _confirmCleanReplace(jsonString);
              },
              child: const Text('Clean Replace'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _executeImport(jsonString, ImportMode.merge);
              },
              child: const Text('Merge (Recommended)'),
            ),
          ],
        );
      },
    );
  }

  void _confirmCleanReplace(String jsonString) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Replace Entire Database?',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          content: const Text(
            'This is a destructive disaster-recovery restore. It will delete all current habits, logs, and progression on this device and replace them with the backup.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _executeImport(jsonString, ImportMode.overwrite);
              },
              child: const Text('Wipe & Restore'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeImport(String jsonString, ImportMode mode) async {
    setState(() {
      _isLoading = true;
      _statusMessage = mode == ImportMode.merge
          ? 'Merging data...'
          : 'Restoring database snapshot...';
    });

    try {
      final service = ref.read(backupServiceProvider);
      final stats = await service.executeImport(jsonString, mode: mode);

      // Invalidate UI streams
      ref.invalidate(activeHabitsStreamProvider);
      ref.invalidate(allLogsStreamProvider);
      ref.invalidate(allShieldsStreamProvider);
      ref.invalidate(playerProgressionStreamProvider);
      ref.invalidate(achievementsStreamProvider);
      ref.invalidate(shieldBankStateStreamProvider);

      // Refresh preferences notifiers
      final prefs = ref.read(themePreferencesProvider);
      ref.read(userNameProvider.notifier).setUserName(prefs.loadUserName());
      ref.read(themeModeProvider.notifier).setThemeMode(prefs.loadThemeMode());
      ref.read(focusDndProvider.notifier).setFocusDndEnabled(prefs.loadFocusDndEnabled());

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = null;
        });
        HapticsHelper.performHeavyConfirmationHaptic();
        final messenger = ScaffoldMessenger.of(context);
        final theme = Theme.of(context);
        final successMessage = mode == ImportMode.merge
            ? 'Import merged successfully (${stats.logsMerged} logs synced)'
            : 'Database restored successfully';
        Navigator.of(context).pop();
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = null;
        });
        _showError('Failed to apply import: $e');
      }
    }
  }

  Widget _buildSummaryRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sync_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data & Backup',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Local offline backups & data portability',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          if (_isLoading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      _statusMessage ?? 'Processing...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Export Full Backup
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.upload_file_outlined,
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 20,
                ),
              ),
              title: const Text(
                'Export Backup (JSON)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Standard unencrypted JSON for data inspection',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showExportOptionsDialog(isEncrypted: false),
            ),
            const SizedBox(height: 4),

            // Export Encrypted Backup
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              title: const Text(
                'Export Encrypted Backup',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Password-protected (AES-256) for secure cloud/email',
              ),
              trailing: const Icon(Icons.share_outlined),
              onTap: _showEncryptedExportDialog,
            ),
            const SizedBox(height: 4),

            // Import Backup
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.download_outlined,
                  color: theme.colorScheme.onTertiaryContainer,
                  size: 20,
                ),
              ),
              title: const Text(
                'Import Backup (JSON)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Merge or restore data from a previous JSON backup',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _handleImportJson,
            ),
            const SizedBox(height: 4),

            // Export CSV
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.table_chart_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              title: const Text(
                'Export Spreadsheets (CSV)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Export habits.csv and habit_logs.csv for Excel or Sheets',
              ),
              trailing: const Icon(Icons.share_outlined),
              onTap: _handleExportCsv,
            ),
          ],
        ],
      ),
    ),
  );
}
}
