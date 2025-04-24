// lib/services/route_service.dart

import 'package:flutter/foundation.dart';

import '../config.dart';
import '../models/route.dart';
import '../models/stop.dart';
import 'database_service.dart';

class RouteService extends ChangeNotifier {
  List<RouteModel> _routes = [];
  RouteModel? _selectedRoute;
  List<Stop> _stops = [];
  bool _demoDataLoaded = false; // to ensure we only import once

  List<RouteModel> get routes => _routes;
  RouteModel? get selectedRoute => _selectedRoute;
  List<Stop> get stops => _stops;

  /// Fetch the list of routes from DB (if testing), or do real logic if production
  Future<void> fetchRoutes() async {
    if (Config.isTesting) {
      if (!_demoDataLoaded) {
        // Optionally load some default file
        await DatabaseService.importDemoFile('assets/demoRoutes/demo_data.txt');
        _demoDataLoaded = true;
      }
      final rawRoutes = await DatabaseService.getRoutes();
      _routes = _deduplicateRoutes(rawRoutes);
      notifyListeners();
    } else {
      // Production logic: maybe request from server
      _routes = [];
      notifyListeners();
    }
  }

  /// Choose a route => fetch stops for it
  Future<void> selectRoute(RouteModel route) async {
    _selectedRoute = route;
    notifyListeners();
    await fetchStops(route.id);
  }

  /// Get all stops for the given routeId from local DB
  Future<void> fetchStops(String routeId) async {
    if (Config.isTesting) {
      _stops = await DatabaseService.getStops(routeId);
      notifyListeners();
    } else {
      // Production: empty or from server
      _stops = [];
      notifyListeners();
    }
  }

  /// Simple reorder in memory
  void reorderStops(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = _stops.removeAt(oldIndex);
    _stops.insert(newIndex, item);
    notifyListeners();
  }

  /// Clear DB, then import a local .txt from assets
  Future<void> importLocalFile(String fileName) async {
    await DatabaseService.clearAllData();
    await DatabaseService.importDemoFile(fileName);

    final rawRoutes = await DatabaseService.getRoutes();
    _routes = _deduplicateRoutes(rawRoutes);
    notifyListeners();
  }

  List<RouteModel> _deduplicateRoutes(List<RouteModel> rawRoutes) {
    final seen = <String>{};
    final result = <RouteModel>[];
    for (var r in rawRoutes) {
      if (!seen.contains(r.id)) {
        seen.add(r.id);
        result.add(r);
      }
    }
    return result;
  }
}
