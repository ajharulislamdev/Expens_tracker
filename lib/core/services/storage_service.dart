import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_constants.dart';

class ExportResult {
  final String path;

  /// True when the public Download folder was not writable and the file
  /// was saved to the app's own external storage instead.
  final bool usedFallback;

  const ExportResult(this.path, {this.usedFallback = false});
}

/// Resolves the export directory: Storage/Download/ExpenseTracker.
class StorageService {
  static const String _androidDownloadPath =
      '/storage/emulated/0/Download/${AppConstants.exportFolder}';

  Future<ExportResult> saveBytes(String fileName, List<int> bytes) async {
    final target = await _resolveDirectory();
    final file = File('${target.dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return ExportResult(file.path, usedFallback: target.usedFallback);
  }

  Future<({Directory dir, bool usedFallback})> _resolveDirectory() async {
    if (Platform.isAndroid) {
      // 1) Try directly (works on most devices / Android 10+ for app-created folders).
      var dir = await _tryCreate(_androidDownloadPath);
      if (dir != null) return (dir: dir, usedFallback: false);

      // 2) Ask for legacy storage permission (Android 9 and below).
      await Permission.storage.request();
      dir = await _tryCreate(_androidDownloadPath);
      if (dir != null) return (dir: dir, usedFallback: false);

      // 3) Ask for "All files access" (Android 11+). Opens system settings.
      final manage = await Permission.manageExternalStorage.request();
      if (manage.isGranted) {
        dir = await _tryCreate(_androidDownloadPath);
        if (dir != null) return (dir: dir, usedFallback: false);
      }

      // 4) Fallback: app-specific external directory (no permission needed).
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        final fallback = await _tryCreate(
          '${ext.path}/${AppConstants.exportFolder}',
        );
        if (fallback != null) return (dir: fallback, usedFallback: true);
      }
    }

    // iOS / desktop / last resort.
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/${AppConstants.exportFolder}');
    if (!await dir.exists()) await dir.create(recursive: true);
    return (dir: dir, usedFallback: Platform.isAndroid);
  }

  /// Creates [path] and verifies it is writable. Returns null on any failure.
  Future<Directory?> _tryCreate(String path) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) await dir.create(recursive: true);
      final probe = File('${dir.path}/.write_test');
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
      return dir;
    } catch (_) {
      return null;
    }
  }
}
