// lib/screens/settings_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';

  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _adminPassCtrl = TextEditingController();
  String _deviceId = 'Loading…';

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    final plugin = DeviceInfoPlugin();
    String id;
    try {
      if (Platform.isAndroid) {
        final androidInfo = await plugin.androidInfo;
        id = androidInfo.id; // use `id` instead of deprecated `androidId`
      } else if (Platform.isIOS) {
        final iosInfo = await plugin.iosInfo;
        id = iosInfo.identifierForVendor ?? 'Unknown';
      } else {
        id = 'Unsupported platform';
      }
    } catch (e) {
      id = 'Error: $e';
    }

    if (mounted) {
      setState(() {
        _deviceId = id;
      });
    }
  }

  @override
  void dispose() {
    _adminPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        children: [
          // Vibrate on Scan
          SwitchListTile(
            title: const Text('Vibrate on Scan'),
            value: settings.vibrateOnScan,
            onChanged: settings.setVibrateOnScan,
          ),

          // Keep Screen On
          SwitchListTile(
            title: const Text('Keep Screen On'),
            value: settings.keepScreenOn,
            onChanged: settings.setKeepScreenOn,
          ),

          const Divider(),

          // Language
          ListTile(
            title: const Text('Language'),
            trailing: DropdownButton<String>(
              value: settings.selectedLanguage,
              items: const [
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'Spanish', child: Text('Spanish')),
              ],
              onChanged: (String? newLang) {
                if (newLang != null) {
                  settings.setSelectedLanguage(newLang);
                }
              },
            ),
          ),

          // Use Maps
          SwitchListTile(
            title: const Text('Use Maps'),
            value: settings.useMaps,
            onChanged: settings.setUseMaps,
          ),

          // Use Speech
          SwitchListTile(
            title: const Text('Use Speech'),
            value: settings.useSpeech,
            onChanged: settings.setUseSpeech,
          ),

          const Divider(),

          // Register Device
          Text('Register Device', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Device ID: $_deviceId'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // TODO: call your API using _deviceId
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Register Device logic goes here')),
              );
            },
            child: const Text('Register Device'),
          ),

          const Divider(),

          // Admin area
          Text('Admin Area', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _adminPassCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Enter Admin Password'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              final adminPass = _adminPassCtrl.text.trim();
              // TODO: your admin logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Admin pass submitted: $adminPass')),
              );
            },
            child: const Text('Submit'),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
