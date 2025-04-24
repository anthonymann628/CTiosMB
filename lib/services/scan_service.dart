// lib/services/scan_service.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/barcode_scan.dart';
import '../widgets/barcode_scanner_viewfinder.dart';
import 'navigation_service.dart';
import '../utils/permissions.dart';

class ScanService {
  static Future<BarcodeScan?> scanBarcode() async {
    final granted = await Permissions.ensureCameraPermission();
    if (!granted) return null;
    // Open scanner page and wait for a result from _BarcodeScannerPage
    return await NavigationService.navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => _BarcodeScannerPage()),
    );
  }
}

class _BarcodeScannerPage extends StatefulWidget {
  @override
  _BarcodeScannerPageState createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _flashOn = false;
  bool _scanned = false;

  void _toggleFlash() {
    setState(() {
      _flashOn = !_flashOn;
      _controller.toggleTorch();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The function signature must match `void Function(BarcodeCapture capture)?`
  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;

    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      _scanned = true;

      // Grab the first recognized barcode
      final code = barcodes.first.rawValue;
      final format = barcodes.first.format; // an enum, can do .name or .toString()
      if (code != null) {
        // Create a BarcodeScan model. Adjust 'type' if needed
        final result = BarcodeScan(code: code, type: format.toString());
        Navigator.of(context).pop(result);
      } else {
        // If first.rawValue is null, allow scanning again
        setState(() => _scanned = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            fit: BoxFit.cover,
            onDetect: _onDetect, // single-argument callback
          ),
          const Center(child: BarcodeScannerViewfinder()),
        ],
      ),
    );
  }
}
