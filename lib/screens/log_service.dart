// lib/services/log_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LogService {
  static const _logFileName = 'carriertrack.log';

  static Future<void> log(String message) async {
    final now = DateTime.now().toIso8601String();
    final entry = '[$now] $message\n';
    final file = await _getLogFile();
    await file.writeAsString(entry, mode: FileMode.append);
  }

  static Future<String> getLogContent() async {
    final file = await _getLogFile();
    if (!file.existsSync()) {
      return 'No log file found.';
    }
    return file.readAsString();
  }

  static Future<File> _getLogFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$_logFileName';
    return File(path);
  }
}
