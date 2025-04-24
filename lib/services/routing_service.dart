// lib/services/routing_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/stop.dart';

class RoutingService {
  static const _directionsBaseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  /// Using Google Directions to optimize route:
  ///  - origin/destination = user location (for round-trip)
  ///  - waypoints = "optimize:true|lat,lng|lat,lng|..."
  ///
  /// Returns:
  ///   - step-by-step polylines (polylinePoints)
  ///   - a single big 'overview_polyline' (overviewEncoded)
  ///   - the optimized stop order
  ///   - rawLegs data for parsing turn-by-turn instructions
  ///
  /// [Note]: The real logic for route optimization is the 'optimize:true'
  /// in the waypoints string, not '&optimize=true'. 
  /// If you want distances in miles, add '&units=imperial'.
  static Future<RouteOptimizationResult> getOptimizedRoute({
    required LatLng userLocation,
    required List<Stop> stops,
    required String googleApiKey,
  }) async {
    // Build "optimize:true|lat,lng|lat,lng..." in a single string
    final waypointStr = _buildWaypointString(stops);

    final origin = '${userLocation.latitude},${userLocation.longitude}';
    final destination = '${userLocation.latitude},${userLocation.longitude}';

    // For clarity, we add '&units=imperial' to get distances in miles.
    // Remove or switch to '&units=metric' if you prefer kilometers.
    final uri = Uri.parse(
      '$_directionsBaseUrl'
      '?origin=$origin'
      '&destination=$destination'
      '&waypoints=$waypointStr'
      '&units=imperial'
      '&key=$googleApiKey'
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Directions API failed with status ${response.statusCode}');
    }
    final data = json.decode(response.body);

    if (data['status'] != 'OK') {
      throw Exception('Directions API status not OK: ${data['status']}');
    }

    // Typically routes[0] is the optimized route if "optimize:true" was used
    final route = data['routes'][0];

    // If 'optimize:true' was used, route['waypoint_order'] is the new order
    final waypointOrder = route['waypoint_order'] as List<dynamic>?;

    // We'll build step-by-step polylines by decoding each step's "polyline"
    final List<LatLng> polylinePoints = [];
    // Store the entire 'legs' array for turn-by-turn instructions
    final rawLegs = route['legs'] as List<dynamic>;

    for (var leg in rawLegs) {
      final steps = leg['steps'] as List<dynamic>;
      for (var step in steps) {
        final encoded = step['polyline']['points'];
        polylinePoints.addAll(decodePolyline(encoded));
      }
    }

    // The big overview polyline for quick drawing
    final overviewEncoded = route['overview_polyline']['points'] as String;

    // Reorder stops based on the returned 'waypoint_order'
    List<Stop> optimizedStops = stops;
    if (waypointOrder != null && waypointOrder.isNotEmpty) {
      optimizedStops = List<Stop>.generate(
        stops.length,
        (i) => stops[waypointOrder[i]],
      );
    }

    return RouteOptimizationResult(
      polylinePoints: polylinePoints,
      overviewEncoded: overviewEncoded,
      optimizedStops: optimizedStops,
      rawLegs: rawLegs, // entire legs array for further parsing
    );
  }

  /// Build "optimize:true" + lat,lng for each Stop
  static String _buildWaypointString(List<Stop> stops) {
    // e.g. "optimize:true|40.1234,-74.5678|40.1357,-74.8901"
    final buffer = StringBuffer('optimize:true');
    for (var s in stops) {
      if (s.latitude == null || s.longitude == null) continue;
      buffer.write('|${s.latitude},${s.longitude}');
    }
    return buffer.toString();
  }

  /// Decodes an encoded polyline string into a list of LatLng
  static List<LatLng> decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result = 0;

      // Decode latitude
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dlat = (result & 1) == 1 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      // Decode longitude
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dlng = (result & 1) == 1 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      final latF = lat / 1E5;
      final lngF = lng / 1E5;
      points.add(LatLng(latF, lngF));
    }

    return points;
  }
}

/// Holds step-by-step polylines + single big overviewEncoded + optimized stops
/// and the entire 'legs' array so we can parse actual instructions if needed.
class RouteOptimizationResult {
  final List<LatLng> polylinePoints; // step-by-step polylines
  final String overviewEncoded;      // big single polyline
  final List<Stop> optimizedStops;
  final List<dynamic> rawLegs;       // entire route legs to parse instructions

  RouteOptimizationResult({
    required this.polylinePoints,
    required this.overviewEncoded,
    required this.optimizedStops,
    required this.rawLegs,
  });
}
