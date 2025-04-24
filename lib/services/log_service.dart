// lib/services/log_service.dart
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

class LogService {
  static const String _logFileName = 'carriertrack.log';

  /// Returns the contents of the log file as a [String].
  static Future<String> getLogContent() async {
    try {
      final file = await _getLogFile();
      if (!file.existsSync()) {
        return 'No log file found.';
      }
      return await file.readAsString();
    } catch (e) {
      return 'Error reading log: $e';
    }
  }

  /// Appends a message to the log file.
  static Future<void> log(String message) async {
    final now = DateTime.now().toIso8601String();
    final logEntry = '[$now] $message\n';

    try {
      final file = await _getLogFile();
      await file.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      // If writing fails, you could handle it, but let's just do nothing or print
      // print('Failed to write log: $e');
    }
  }

  /// Returns the log file object.
  static Future<File> _getLogFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$_logFileName';
    return File(path);
  }
}
