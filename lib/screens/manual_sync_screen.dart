// lib/screens/manual_sync_screen.dart
import 'package:flutter/material.dart';

class ManualSyncScreen extends StatefulWidget {
  static const routeName = '/manualSync';

  const ManualSyncScreen({Key? key}) : super(key: key);

  @override
  State<ManualSyncScreen> createState() => _ManualSyncScreenState();
}

class _ManualSyncScreenState extends State<ManualSyncScreen> {
  bool _isSyncing = false;
  String _message = 'Idle';

  Future<void> _performSync() async {
    setState(() {
      _isSyncing = true;
      _message = 'Sync in progress...';
    });

    try {
      // TODO: call your sync service logic
      await Future.delayed(const Duration(seconds: 2)); // simulate
      setState(() => _message = 'Sync complete!');
    } catch (e) {
      setState(() => _message = 'Sync failed: $e');
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Sync'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_message),
            const SizedBox(height: 16),
            _isSyncing
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _performSync,
                    child: const Text('Sync Now'),
                  ),
          ],
        ),
      ),
    );
  }
}
