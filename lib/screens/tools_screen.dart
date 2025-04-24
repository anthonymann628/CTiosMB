// lib/screens/tools_screen.dart
import 'package:flutter/material.dart';
import 'device_status_screen.dart';
import 'manual_sync_screen.dart';
import 'settings_screen.dart';
import 'log_viewer_screen.dart';

class ToolsScreen extends StatelessWidget {
  static const routeName = '/tools';

  const ToolsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = [
      {'title': 'Device Status', 'route': DeviceStatusScreen.routeName},
      {'title': 'Manual Sync', 'route': ManualSyncScreen.routeName},
      {'title': 'Settings', 'route': SettingsScreen.routeName},
      {'title': 'Logs', 'route': LogViewerScreen.routeName},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Tools')),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            title: Text(item['title']!),
            onTap: () {
              Navigator.pushNamed(context, item['route']!);
            },
          );
        },
      ),
    );
  }
}
