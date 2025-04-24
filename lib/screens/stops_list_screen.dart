import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart'; // For checking connectivity
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../models/stop.dart';
import '../services/route_service.dart';
import '../services/routing_service.dart';
import '../services/database_service.dart';
import '../widgets/bottom_nav_bar.dart';

class StopsListScreen extends StatefulWidget {
  static const routeName = '/stopsList';

  const StopsListScreen({Key? key}) : super(key: key);

  @override
  State<StopsListScreen> createState() => _StopsListScreenState();
}

/// A helper class to store each navigation step: end location + textual instruction
class _NavStep {
  final LatLng endLocation;
  final String instruction;
  _NavStep({required this.endLocation, required this.instruction});
}

class _StopsListScreenState extends State<StopsListScreen> {
  // MAP & LOCATION
  final Completer<GoogleMapController> _mapController = Completer();
  final Set<Marker> _stopMarkers = {};
  final Set<Polyline> _polylines = {};

  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;

  // Off-route logic (for the main route)
  List<LatLng> _currentRoutePoints = [];
  DateTime _lastRerouteTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _reRouteCooldownSeconds = 30;
  static const double _offRouteThresholdMeters = 80.0;

  bool _processing = false;
  String? _error;

  // CONSTANTS & CONFIG
  static const String googleApiKey = 'AIzaSyBsvPbA-EkeH3YM16tPb23XfDlf3rKrRrk'; // <--- Insert your key
  static const double _completionRadiusMeters = 91.44; // ~100 yards
  static const double _stepCompletionRadius = 35.0;    // ~115 ft for step completion

  // TEXT-TO-SPEECH & NAV
  late FlutterTts _flutterTts;
  bool _voiceEnabled = true;
  bool _navigationActive = false;
  List<_NavStep> _navSteps = [];
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initLocationTracking();
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage('en-US');
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // LOCATION TRACKING
  // ---------------------------------------------------------------------------
  Future<void> _initLocationTracking() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {});

      // Listen for changes
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).listen((pos) {
        setState(() => _currentPosition = pos);
        _moveCameraTo(pos.latitude, pos.longitude);

        // auto-complete if near stop
        _autoCompleteStopsIfNearby();

        // if nav active => check step & off-route
        if (_navigationActive) {
          _checkStepCompletion();
          _checkOffRoute();
        }
      });
    } catch (e) {
      setState(() => _error = 'Failed to get location: $e');
    }
  }

  Future<void> _moveCameraTo(double lat, double lng) async {
    final ctrl = await _mapController.future;
    final pos = CameraPosition(target: LatLng(lat, lng), zoom: 14.5);
    ctrl.animateCamera(CameraUpdate.newCameraPosition(pos));
  }

  Future<void> _autoCompleteStopsIfNearby() async {
    if (_currentPosition == null) return;

    final routeService = context.read<RouteService>();
    final allStops = routeService.stops;
    final incomplete = allStops.where((s) => !s.completed).toList();

    for (final stop in incomplete) {
      if (stop.latitude == null || stop.longitude == null) continue;
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        stop.latitude!,
        stop.longitude!,
      );
      if (distance <= _completionRadiusMeters) {
        // mark as done
        stop.completed = true;
        stop.completedAt = DateTime.now();
        await DatabaseService.updateStopDelivered(stop);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Stop Completed: ${stop.address}')),
          );
        }
        setState(() {});
      }
    }
  }

  // ---------------------------------------------------------------------------
  // STEP COMPLETION & OFF-ROUTE
  // ---------------------------------------------------------------------------
  void _checkStepCompletion() {
    if (_navSteps.isEmpty || _currentNavIndex >= _navSteps.length) return;
    if (_currentPosition == null) return;

    final step = _navSteps[_currentNavIndex];
    final dist = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      step.endLocation.latitude,
      step.endLocation.longitude,
    );
    if (dist < _stepCompletionRadius) {
      if (_currentNavIndex < _navSteps.length - 1) {
        _currentNavIndex++;
        if (_voiceEnabled) {
          _speak(_navSteps[_currentNavIndex].instruction);
        }
        setState(() {});
      } else {
        // done
        _navSteps.clear();
        _currentNavIndex = 0;
        _navigationActive = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Navigation complete!')),
          );
        }
        setState(() {});
      }
    }
  }

  void _checkOffRoute() {
    if (_currentRoutePoints.isEmpty || _currentPosition == null) return;
    double minDist = double.infinity;
    for (final pt in _currentRoutePoints) {
      final dist = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        pt.latitude,
        pt.longitude,
      );
      if (dist < minDist) minDist = dist;
    }

    if (minDist > _offRouteThresholdMeters) {
      final now = DateTime.now();
      if (now.difference(_lastRerouteTime).inSeconds > _reRouteCooldownSeconds) {
        _lastRerouteTime = now;
        if (_voiceEnabled) {
          _speak('You appear off-course. Recalculating...');
        }
        _reRoute();
      }
    }
  }

  Future<void> _reRoute() async {
    final rs = context.read<RouteService>();
    final incomplete = rs.stops.where((s) => !s.completed).toList();
    // We'll attempt the normal approach. If offline, do naive fallback
    await _optimizeRoute(incomplete, side: 'auto');
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final routeService = context.watch<RouteService>();
    final allStops = routeService.stops;
    final selectedRoute = routeService.selectedRoute;
    final incomplete = allStops.where((s) => !s.completed).toList();

    // Build markers
    _stopMarkers.clear();
    for (final st in incomplete) {
      if (st.latitude != null && st.longitude != null) {
        _stopMarkers.add(
          Marker(
            markerId: MarkerId('stop_${st.id}'),
            position: LatLng(st.latitude!, st.longitude!),
            infoWindow: InfoWindow(title: st.name, snippet: st.address),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Stops - ${selectedRoute?.name ?? ""}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              if (selectedRoute != null) {
                setState(() => _processing = true);
                try {
                  await routeService.fetchStops(selectedRoute.id);
                  await _loadCachedRoutePolyline(selectedRoute.id);
                } catch (e) {
                  setState(() => _error = 'Failed to refresh stops: $e');
                } finally {
                  setState(() => _processing = false);
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            tooltip: 'Optimize Route',
            onPressed: () {
              if (incomplete.isNotEmpty) {
                _optimizeRoute(incomplete, side: 'auto');
              } else {
                setState(() => _error = 'No incomplete stops to optimize.');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_currentPosition != null) {
                _moveCameraTo(_currentPosition!.latitude, _currentPosition!.longitude);
              }
            },
          ),
          // End route
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined),
            tooltip: 'End Route',
            onPressed: _endRoute,
          ),
          // Reset route
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset Route',
            onPressed: _confirmResetRoute,
          ),
        ],
      ),
      body: _buildBody(allStops),
      bottomNavigationBar: const CarrierTrackBottomNav(),
    );
  }

  // RESET ROUTE
  Future<void> _confirmResetRoute() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Route?'),
        content: const Text(
          'This will mark all stops as incomplete again. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _resetRoute();
    }
  }

  Future<void> _resetRoute() async {
    final routeService = context.read<RouteService>();
    final selectedRoute = routeService.selectedRoute;
    if (selectedRoute == null) return;

    // mark all incomplete
    final stopsForRoute = await DatabaseService.getStops(selectedRoute.id);
    for (final stop in stopsForRoute) {
      stop.completed = false;
      stop.completedAt = null;
      stop.uploaded = false;
      await DatabaseService.updateStopDelivered(stop);
    }

    // re-fetch
    await routeService.fetchStops(selectedRoute.id);

    // clear nav
    setState(() {
      _navigationActive = false;
      _navSteps.clear();
      _currentNavIndex = 0;
      _polylines.clear();
      _currentRoutePoints.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Route has been reset.')),
    );
  }

  // BODY LAYOUT
  Widget _buildBody(List<Stop> allStops) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    if (isLandscape) {
      return Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(child: _buildMap()),
                    _buildStartRouteButton(allStops),
                  ],
                ),
                if (_navigationActive) _buildNavOverlay(),
              ],
            ),
          ),
          Expanded(child: _buildStopsList(allStops)),
        ],
      );
    } else {
      return Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(child: _buildMap()),
                    _buildStartRouteButton(allStops),
                  ],
                ),
                if (_navigationActive) _buildNavOverlay(),
              ],
            ),
          ),
          Expanded(child: _buildStopsList(allStops)),
        ],
      );
    }
  }

  Widget _buildMap() {
    double lat = 40.0, lng = -74.0;
    if (_currentPosition != null) {
      lat = _currentPosition!.latitude;
      lng = _currentPosition!.longitude;
    }
    final initPos = CameraPosition(target: LatLng(lat, lng), zoom: 14);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: initPos,
          markers: _stopMarkers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          onMapCreated: (ctrl) => _mapController.complete(ctrl),
        ),
        if (_processing)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildStopsList(List<Stop> allStops) {
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (allStops.isEmpty) {
      return const Center(child: Text('No stops found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: allStops.length,
      itemBuilder: (context, i) {
        final st = allStops[i];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(st.address),
            subtitle: Text('Completed: ${st.completed ? "Yes" : "No"}'),
            trailing: Icon(
              st.completed ? Icons.check_circle : Icons.radio_button_unchecked,
              color: st.completed ? Colors.green : null,
            ),
            onTap: () async {
              final changed = await Navigator.pushNamed(
                context,
                '/stopDetail',
                arguments: st.id,
              );
              if (changed == true) {
                final rs = context.read<RouteService>();
                final sel = rs.selectedRoute;
                if (sel != null) {
                  await rs.fetchStops(sel.id);
                }
                setState(() {});
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildStartRouteButton(List<Stop> allStops) {
    final incomplete = allStops.where((s) => !s.completed).toList();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Route'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
        onPressed: () {
          if (incomplete.isEmpty) {
            setState(() => _error = 'No incomplete stops to start a route with.');
          } else {
            _showSideSelectionDialog(incomplete);
          }
        },
      ),
    );
  }

  Future<void> _showSideSelectionDialog(List<Stop> incompleteStops) async {
    String? localSelected;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Delivery Mode'),
        content: StatefulBuilder(
          builder: (ctx2, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('L/R Hand Delivery'),
                  value: 'LR',
                  groupValue: localSelected,
                  onChanged: (val) => setStateDialog(() => localSelected = val),
                ),
                RadioListTile<String>(
                  title: const Text('Left Side Delivery'),
                  value: 'Left',
                  groupValue: localSelected,
                  onChanged: (val) => setStateDialog(() => localSelected = val),
                ),
                RadioListTile<String>(
                  title: const Text('Right Side Delivery'),
                  value: 'Right',
                  groupValue: localSelected,
                  onChanged: (val) => setStateDialog(() => localSelected = val),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, localSelected),
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );

    if (result != null) {
      _optimizeRoute(incompleteStops, side: result);
    }
  }

  // ---------------------------------------------------------------------------
  // OPTION A: TRY GOOGLE FIRST, ELSE FALLBACK
  // ---------------------------------------------------------------------------
  Future<void> _optimizeRoute(List<Stop> incompleteStops, {String? side}) async {
    if (_currentPosition == null) {
      setState(() => _error = 'No current location to optimize from.');
      return;
    }
    if (incompleteStops.isEmpty) {
      setState(() => _error = 'No incomplete stops to optimize.');
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      // 1) Check if we have connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasNetwork = connectivityResult != ConnectivityResult.none;

      // 2) If we DO have network, try Google Directions
      if (hasNetwork) {
        final rs = context.read<RouteService>();
        final sel = rs.selectedRoute;
        if (sel == null) {
          throw Exception('No selected route to store polyline.');
        }
        debugPrint('Chosen side = $side (placeholder)');

        final userLatLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
        final result = await RoutingService.getOptimizedRoute(
          userLocation: userLatLng,
          stops: incompleteStops,
          googleApiKey: googleApiKey,
        );

        // Resequence
        for (int i = 0; i < result.optimizedStops.length; i++) {
          result.optimizedStops[i].sequence = i;
        }
        await DatabaseService.updateStopSequence(result.optimizedStops);

        // Save big polyline
        await DatabaseService.saveRoutePolyline(
          routeId: sel.id,
          encodedPolyline: result.overviewEncoded,
        );

        // Refresh stops
        await rs.fetchStops(sel.id);

        // Clear polylines & draw new
        _polylines.clear();
        final lineId = const PolylineId('optimized_route');
        _polylines.add(
          Polyline(
            polylineId: lineId,
            width: 5,
            color: Colors.blue,
            points: result.polylinePoints,
          ),
        );

        // For off-route detection
        _currentRoutePoints = result.polylinePoints;

        // Build step instructions
        _navSteps = _parseStepsFromLegs(result.rawLegs);
        _currentNavIndex = 0;
        _navigationActive = true;

        // Greet user
        if (_voiceEnabled) {
          _speak('Welcome to Carrier Track. Let\'s start your route safely!');
          if (_navSteps.isNotEmpty) {
            await Future.delayed(const Duration(milliseconds: 800));
            _speak(_navSteps.first.instruction);
          }
        }
        setState(() {});
      } else {
        // 3) OFFLINE => do naive fallback
        debugPrint('Offline fallback: connecting stops in a simple line.');

        // Sort incomplete by sequence (or lat/lng). We'll assume 'sequence' is meaningful.
        // We also can add user’s current position as the start if we want.
        final sortedStops = List<Stop>.from(incompleteStops)
          ..sort((a, b) => a.sequence.compareTo(b.sequence));

        // Build a simple polyline of userLocation -> stop1 -> stop2...
        final routePoints = <LatLng>[];
        routePoints.add( // start from user's location
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        );
        for (final st in sortedStops) {
          if (st.latitude != null && st.longitude != null) {
            routePoints.add(LatLng(st.latitude!, st.longitude!));
          }
        }

        // clear old & draw new
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('offline_fallback'),
            width: 5,
            color: Colors.orange,
            points: routePoints,
          ),
        );
        _currentRoutePoints = routePoints;

        // No step-based instructions => just a single “head to next stop” approach
        _navSteps.clear();
        _navigationActive = false; // No real step-by-step offline

        // If you want a TTS greeting anyway:
        if (_voiceEnabled) {
          _speak('Offline mode. A simple route line has been drawn. Drive safely.');
        }

        setState(() {});
      }
    } catch (e) {
      setState(() => _error = 'Failed to optimize route: $e');
    } finally {
      setState(() => _processing = false);
    }
  }

  // Parsing rawLegs => list of steps
  List<_NavStep> _parseStepsFromLegs(List<dynamic> rawLegs) {
    final stepsList = <_NavStep>[];
    for (final leg in rawLegs) {
      final steps = leg['steps'] as List<dynamic>;
      for (final step in steps) {
        final end = step['end_location'];
        final lat = (end['lat'] as num).toDouble();
        final lng = (end['lng'] as num).toDouble();
        final instruction = (step['html_instructions'] as String?) ?? '';
        stepsList.add(
          _NavStep(
            endLocation: LatLng(lat, lng),
            instruction: instruction,
          ),
        );
      }
    }
    return stepsList;
  }

  // NAV OVERLAY
  Widget _buildNavOverlay() {
    String currentStep = 'No more steps.';
    if (_currentNavIndex < _navSteps.length) {
      currentStep = _navSteps[_currentNavIndex].instruction;
    }
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          color: Colors.black54,
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          child: Text(
            _stripHtml(currentStep),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }

  // END ROUTE
  Future<void> _endRoute() async {
    final rs = context.read<RouteService>();
    final allStops = rs.stops;
    final incompleteCount = allStops.where((s) => !s.completed).length;
    final completedCount = allStops.length - incompleteCount;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Route?'),
        content: Text(
          'Stops remaining: $incompleteCount\n'
          'Stops completed: $completedCount\n\n'
          'Are you sure you want to end the route?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, End'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final bool? syncNow = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sync Data?'),
          content: const Text('Do you want to sync your route data now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (syncNow == true) {
        debugPrint('Syncing route data...');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data synced!')),
          );
        }
      }

      setState(() {
        _navigationActive = false;
        _navSteps.clear();
        _currentNavIndex = 0;
      });

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  // MANUAL STEP SKIP (if we want it)
  void _nextManualStep() {
    if (_currentNavIndex < _navSteps.length - 1) {
      _currentNavIndex++;
      if (_voiceEnabled) {
        _speak(_navSteps[_currentNavIndex].instruction);
      }
      setState(() {});
    } else {
      // done
      _navigationActive = false;
      _navSteps.clear();
      _currentNavIndex = 0;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All steps completed!')),
        );
      }
      setState(() {});
    }
  }

  // UTILS
  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  Future<void> _speak(String text) async {
    if (!_voiceEnabled) return;
    final plain = _stripHtml(text);
    await _flutterTts.stop();
    await _flutterTts.speak(plain);
  }

  Future<void> _loadCachedRoutePolyline(String routeId) async {
    final encoded = await DatabaseService.getRoutePolyline(routeId);
    if (encoded == null) return;
    final points = RoutingService.decodePolyline(encoded);
    _polylines.clear();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('cached_route'),
        width: 5,
        color: Colors.blue,
        points: points,
      ),
    );
    _currentRoutePoints = points;
    setState(() {});
  }
}
