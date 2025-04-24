import 'package:flutter/foundation.dart';

import '../models/stop.dart';
import 'database_service.dart';

class DeliveryService extends ChangeNotifier {
  Future<void> attachBarcode(Stop stop, String code) async {
    stop.barcodes.add(code);
    // persist if you like: await DatabaseService.insertBarcodeScan(...)
    notifyListeners();
  }

  /// Now accepts optional geo-tags
  Future<void> attachPhoto(
    Stop stop,
    String photoPath, {
    double? latitude,
    double? longitude,
  }) async {
    stop.photoPath = photoPath;

    // 1) Persist the photo row (with geo if available)
    await DatabaseService.insertPhoto(
      stopId: stop.id,
      filePath: photoPath,
      latitude: latitude,
      longitude: longitude,
    );

    // 2) Also update the main Stops table's lat/long
    if (latitude != null && longitude != null) {
      stop.latitude = latitude;
      stop.longitude = longitude;
      await DatabaseService.updateStopLocation(
        stop.id,
        latitude,
        longitude,
      );
    }

    notifyListeners();
  }

  Future<void> attachSignature(
      Stop stop, String signaturePath) async {
    stop.signaturePath = signaturePath;
    // persist signature if you like
    notifyListeners();
  }

  Future<void> completeStop(Stop stop) async {
    stop.completed = true;
    stop.completedAt = DateTime.now();

    // upload / persist
    try {
      await _uploadStop(stop);
      stop.uploaded = true;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading stop: $e');
      }
    }

    notifyListeners();
  }

  Future<void> _uploadStop(Stop stop) async {
    // persist main stop row
    await DatabaseService.updateStopDelivered(stop);
  }
}
