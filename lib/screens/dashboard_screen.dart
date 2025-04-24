// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../services/route_service.dart';
import 'route_select_screen.dart';
import 'device_status_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  static const routeName = '/dashboard';

  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _requestEssentialPermissions();
  }

  Future<void> _requestEssentialPermissions() async {
    // Request Location (when in use), Camera & Microphone up front:
    await [
      Permission.locationWhenInUse,
      Permission.camera,
      Permission.microphone,
    ].request();
    // You can inspect the returned statuses if you want:
    // final statuses = await [...].request();
    // debugPrint('Permissions: $statuses');
  }

  @override
  Widget build(BuildContext context) {
    final routeService = context.read<RouteService>();

    final dashboardItems = [
      _DashboardItem(
        label: 'Deliver',
        icon: Icons.local_shipping,
        onTap: () {
          Navigator.pushNamed(context, RouteSelectScreen.routeName);
        },
      ),
      _DashboardItem(
        label: 'Device Status',
        icon: Icons.device_thermostat,
        onTap: () {
          Navigator.pushNamed(context, DeviceStatusScreen.routeName);
        },
      ),
      _DashboardItem(
        label: 'Settings',
        icon: Icons.settings,
        onTap: () {
          Navigator.pushNamed(context, SettingsScreen.routeName);
        },
      ),
      _DashboardItem(
        label: 'Manual Sync',
        icon: Icons.sync,
        onTap: () async {
          try {
            await routeService.fetchRoutes();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sync completed.')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sync failed: $e')),
            );
          }
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children:
              dashboardItems.map((item) => _DashboardCard(item: item)).toList(),
        ),
      ),
    );
  }
}

class _DashboardItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  _DashboardItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class _DashboardCard extends StatelessWidget {
  final _DashboardItem item;

  const _DashboardCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                item.label,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
