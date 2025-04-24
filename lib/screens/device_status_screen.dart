// lib/screens/device_status_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:disk_space/disk_space.dart';

class DeviceStatusScreen extends StatefulWidget {
  static const routeName = '/deviceStatus';
  const DeviceStatusScreen({Key? key}) : super(key: key);

  @override
  State<DeviceStatusScreen> createState() => _DeviceStatusScreenState();
}

class _DeviceStatusScreenState extends State<DeviceStatusScreen>
    with WidgetsBindingObserver {
  // ── Permissions
  bool _gpsEnabled = false;
  bool _gpsPermGranted = false;
  bool _cameraPermGranted = false;
  bool _micPermGranted = false;

  // ── System Info
  String _networkStatus = 'Loading…';
  String _availableMemory = 'Loading…';
  String _installedVersion = 'Loading…';

  bool _loading = false;

  late final StreamSubscription _connectivitySub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Subscribe to connectivity changes (plural onConnectivityChanged emits List<ConnectivityResult>)
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((dynamic result) => _onConnectivityChanged(result));
    _refreshAllStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAllStatuses();
    }
  }

  Future<void> _refreshAllStatuses() async {
    setState(() => _loading = true);

    // pick up initial connectivity state
    final initial = await Connectivity().checkConnectivity();
    _onConnectivityChanged(initial);

    // brief delay to show spinner
    await Future.delayed(const Duration(seconds: 1));

    await Future.wait([
      _checkPermissions(),
      _checkAvailableMemory(),
      _checkInstalledVersion(),
    ]);

    setState(() => _loading = false);
  }

  // Handles both single and list results:
  void _onConnectivityChanged(dynamic result) {
    List<ConnectivityResult> list;
    if (result is ConnectivityResult) {
      list = [result];
    } else if (result is List<ConnectivityResult>) {
      list = result;
    } else {
      list = [];
    }

    String status;
    if (list.contains(ConnectivityResult.wifi)) {
      status = 'Wi-Fi';
    } else if (list.contains(ConnectivityResult.mobile)) {
      status = 'Cellular Data';
    } else if (list.contains(ConnectivityResult.ethernet)) {
      status = 'Ethernet';
    } else if (list.contains(ConnectivityResult.bluetooth)) {
      status = 'Bluetooth';
    } else if (list.contains(ConnectivityResult.vpn)) {
      status = 'VPN';
    } else if (list.contains(ConnectivityResult.none) || list.isEmpty) {
      status = 'No Connection';
    } else {
      status = 'Unknown';
    }

    setState(() => _networkStatus = status);
  }

  //--------------------------------------------------------------------------
  // PERMISSIONS
  //--------------------------------------------------------------------------

  Future<void> _checkPermissions() async {
    _gpsEnabled = await Geolocator.isLocationServiceEnabled();
    final locPerm = await Geolocator.checkPermission();
    _gpsPermGranted = locPerm == LocationPermission.always ||
        locPerm == LocationPermission.whileInUse;

    _cameraPermGranted = await Permission.camera.isGranted;
    _micPermGranted = await Permission.microphone.isGranted;

    setState(() {});
  }

  Future<void> _requestGpsPermission() async {
    final perm = await Geolocator.requestPermission();
    _gpsPermGranted =
        perm == LocationPermission.always || perm == LocationPermission.whileInUse;
    _gpsEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() {});
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      _showOpenSettingsDialog('Camera permission permanently denied.');
    }
    _cameraPermGranted = status.isGranted;
    setState(() {});
  }

  Future<void> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    if (status.isPermanentlyDenied) {
      _showOpenSettingsDialog('Microphone permission permanently denied.');
    }
    _micPermGranted = status.isGranted;
    setState(() {});
  }

  void _showOpenSettingsDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  //--------------------------------------------------------------------------
  // DISK SPACE
  //--------------------------------------------------------------------------

  Future<void> _checkAvailableMemory() async {
    try {
      final free = await DiskSpace.getFreeDiskSpace;
      _availableMemory =
          free != null ? '${free.toStringAsFixed(1)} MB free' : 'Unknown';
    } catch (_) {
      _availableMemory = 'Error';
    }
    setState(() {});
  }

  //--------------------------------------------------------------------------
  // VERSION INFO
  //--------------------------------------------------------------------------

  Future<void> _checkInstalledVersion() async {
    final info = await PackageInfo.fromPlatform();
    _installedVersion = 'v${info.version}+${info.buildNumber}';
    setState(() {});
  }

  //--------------------------------------------------------------------------
  // UI
  //--------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Status')),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshAllStatuses,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Device Status',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),

                  // ── Permissions ──────────────────────────────
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Permissions',
                              style: Theme.of(context).textTheme.titleMedium),
                          const Divider(),
                          _PermissionRow(
                            label: 'GPS',
                            enabled: _gpsEnabled && _gpsPermGranted,
                            description: _gpsEnabled
                                ? (_gpsPermGranted
                                    ? 'On & Granted'
                                    : 'On but Denied')
                                : 'Off',
                            onToggle: _requestGpsPermission,
                          ),
                          const SizedBox(height: 8),
                          _PermissionRow(
                            label: 'Camera',
                            enabled: _cameraPermGranted,
                            onToggle: _requestCameraPermission,
                          ),
                          const SizedBox(height: 8),
                          _PermissionRow(
                            label: 'Microphone',
                            enabled: _micPermGranted,
                            onToggle: _requestMicPermission,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── System Info ────────────────────────────────
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('System Info',
                              style: Theme.of(context).textTheme.titleMedium),
                          const Divider(),
                          _StatusTile(
                              label: 'Network', value: _networkStatus),
                          const SizedBox(height: 8),
                          _StatusTile(
                              label: 'Available Memory',
                              value: _availableMemory),
                          const SizedBox(height: 8),
                          _StatusTile(
                              label: 'App Version',
                              value: _installedVersion),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _downloadLog,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48)),
                    child: const Text('Download Logs'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _uploadLog,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48)),
                    child: const Text('Upload Logs'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refreshAllStatuses,
                    icon: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Refresh Status'),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48)),
                  ),
                ],
              ),
            ),
          ),

          if (_loading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  void _downloadLog() => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading logs…')));
  void _uploadLog() => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading logs…')));
}

//──────────────────────────────────────────────────────────────────────────────
// PERMISSION ROW
//──────────────────────────────────────────────────────────────────────────────
class _PermissionRow extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onToggle;
  final String? description;

  const _PermissionRow({
    Key? key,
    required this.label,
    required this.enabled,
    required this.onToggle,
    this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final desc = description ?? (enabled ? 'Granted' : 'Denied');
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(desc, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Switch(value: enabled, onChanged: (_) => onToggle()),
      ],
    );
  }
}

//──────────────────────────────────────────────────────────────────────────────
// STATUS TILE
//──────────────────────────────────────────────────────────────────────────────
class _StatusTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatusTile({Key? key, required this.label, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
