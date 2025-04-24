// lib/services/app_state.dart

import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/stop.dart';
import '../models/barcode_scan.dart';
import '../models/photo.dart';
import '../models/signature.dart';

class AppState extends ChangeNotifier {
  // ------------------- User Auth State -------------------
  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  void setUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    // Clear any loaded stops if you want to reset app state on logout
    stops.clear();
    notifyListeners();
  }

  // --------------------- Stop Data -----------------------
  /// A list of stops loaded for the current route/day
  List<Stop> stops = [];

  /// Replace the existing stops list (e.g., after fetching from server/DB).
  void setStops(List<Stop> newStops) {
    stops = newStops;
    notifyListeners();
  }

  /// Add a barcode scan to the specified stop. The code is appended to the stop's barcodes list.
  void addBarcodeScan(String stopId, BarcodeScan scan) {
    try {
      final int idInt = int.tryParse(stopId) ?? -1;
      final stop = stops.firstWhere((s) => s.id == idInt);
      stop.barcodes.add(scan.code);
      notifyListeners();
    } catch (_) {
      // Stop not found or other error
    }
  }

  /// Attach a photo by setting the stop's `photoPath` (if your model only stores one photo).
  /// If you store multiple photos, you'd add it to a list instead.
  void addPhoto(String stopId, Photo photo) {
    try {
      final int idInt = int.tryParse(stopId) ?? -1;
      final stop = stops.firstWhere((s) => s.id == idInt);
      stop.photoPath = photo.filePath;
      notifyListeners();
    } catch (_) {
      // Stop not found or other error
    }
  }

  /// Attach a signature by setting the stop's `signaturePath`.
  void setSignature(String stopId, Signature signature) {
    try {
      final int idInt = int.tryParse(stopId) ?? -1;
      final stop = stops.firstWhere((s) => s.id == idInt);
      stop.signaturePath = signature.filePath;
      notifyListeners();
    } catch (_) {
      // Stop not found or other error
    }
  }

  /// Mark a stop as delivered/completed, optionally updating the time and GPS coords if provided.
  void markStopDelivered(String stopId, {DateTime? deliveredAt, double? lat, double? lng}) {
    try {
      final int idInt = int.tryParse(stopId) ?? -1;
      final stop = stops.firstWhere((s) => s.id == idInt);
      stop.completed = true;
      stop.completedAt = deliveredAt;  // assign delivered time if provided
      stop.latitude = lat;
      stop.longitude = lng;
      notifyListeners();
    } catch (_) {
      // Stop not found or other error
    }
  }
}
