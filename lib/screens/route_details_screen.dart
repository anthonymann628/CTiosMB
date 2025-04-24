// lib/screens/route_details_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for SystemChrome
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../models/stop.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../widgets/bottom_nav_bar.dart';

class RouteDetailsScreen extends StatefulWidget {
  static const routeName = '/routeDetails';

  const RouteDetailsScreen({Key? key}) : super(key: key);

  @override
  _RouteDetailsScreenState createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  bool _processing = false;
  String? _error;

  late List<Stop> _stops;

  // For Google Maps
  final Completer<GoogleMapController> _mapController = Completer();
  final Set<Marker> _stopMarkers = {};
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    // Force landscape orientation for this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      _initLocationTracking();
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    // Optional: restore orientation if you only want to lock it on this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    // 1) Request permission if needed
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    // 2) Get current position
    _currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {});

    // 3) Listen for position changes
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((pos) {
      setState(() => _currentPosition = pos);
      // Optionally move camera automatically
      _moveCameraTo(pos.latitude, pos.longitude);
    });
  }

  Future<void> _moveCameraTo(double lat, double lng) async {
    final ctrl = await _mapController.future;
    final pos = CameraPosition(target: LatLng(lat, lng), zoom: 14.5);
    ctrl.animateCamera(CameraUpdate.newCameraPosition(pos));
  }

  @override
  Widget build(BuildContext context) {
    // 1) get stops from route arguments
    _stops = (ModalRoute.of(context)?.settings.arguments as List<Stop>?) ?? [];

    // 2) Build markers from stops
    _stopMarkers.clear();
    for (var s in _stops) {
      if (s.latitude != null && s.longitude != null) {
        final marker = Marker(
          markerId: MarkerId('stop_${s.id}'),
          position: LatLng(s.latitude!, s.longitude!),
          infoWindow: InfoWindow(
            title: s.name,
            snippet: s.address,
          ),
          onTap: () {
            // Possibly do something on marker tap
          },
        );
        _stopMarkers.add(marker);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_currentPosition != null) {
                _moveCameraTo(_currentPosition!.latitude, _currentPosition!.longitude);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // We'll build a horizontal split: map on left, list on right
          Row(
            children: [
              // Left side: the map
              Expanded(
                flex: 2, // 2/3 of screen
                child: _buildMap(),
              ),
              // Right side: a list of stops
              Expanded(
                flex: 1, // 1/3 of screen
                child: Container(
                  color: Colors.white70,
                  child: _buildStopList(),
                ),
              ),
            ],
          ),
          if (_processing)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      bottomNavigationBar: const CarrierTrackBottomNav(),
    );
  }

  Widget _buildMap() {
    // initial camera position, fallback to first stop or some default
    double initLat = 40.0, initLng = -74.0; // fallback
    if (_stops.isNotEmpty && _stops.first.latitude != null) {
      initLat = _stops.first.latitude!;
      initLng = _stops.first.longitude!;
    }
    if (_currentPosition != null) {
      initLat = _currentPosition!.latitude;
      initLng = _currentPosition!.longitude;
    }

    final initialPos = CameraPosition(
      target: LatLng(initLat, initLng),
      zoom: 14,
    );

    return GoogleMap(
      initialCameraPosition: initialPos,
      markers: _stopMarkers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false, // we have our own in AppBar
      onMapCreated: (controller) => _mapController.complete(controller),
    );
  }

  Widget _buildStopList() {
    if (_stops.isEmpty) {
      return const Center(child: Text('No stops found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _stops.length,
      itemBuilder: (context, index) {
        final stop = _stops[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(stop.name),
            subtitle: Text(stop.address),
            trailing: Icon(
              stop.completed ? Icons.check_circle : Icons.radio_button_unchecked,
              color: stop.completed ? Colors.green : null,
            ),
            onTap: () => _completeStop(stop),
          ),
        );
      },
    );
  }

  Future<void> _completeStop(Stop stop) async {
    if (_processing) return;
    setState(() => _processing = true);

    try {
      await DatabaseService.insertBarcodeScan(
        stopId: stop.id,
        code: 'TEST123',
        type: 'QR',
      );
      await DatabaseService.insertPhoto(
        stopId: stop.id,
        filePath: '/path/to/photo.jpg',
      );
      await DatabaseService.insertSignature(
        stopId: stop.id,
        filePath: '/path/to/signature.png',
        signerName: 'John Doe',
      );

      stop.completed = true;
      stop.completedAt = DateTime.now();
      await DatabaseService.updateStopDelivered(stop);

      await SyncService.syncStopData(stop);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stop #${stop.id} completed.')),
      );
    } catch (e) {
      setState(() => _error = 'Failed to complete stop: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error!)),
      );
    } finally {
      setState(() => _processing = false);
    }
  }
}
