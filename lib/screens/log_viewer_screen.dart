// lib/screens/log_viewer_screen.dart
import 'package:flutter/material.dart';
import '../services/log_service.dart';


class LogViewerScreen extends StatefulWidget {
  static const routeName = '/logViewer';

  const LogViewerScreen({Key? key}) : super(key: key);

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  String _logContent = '';

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  Future<void> _loadLog() async {
    final content = await LogService.getLogContent(); // must exist
    setState(() => _logContent = content);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Text(_logContent),
      ),
    );
  }
}
