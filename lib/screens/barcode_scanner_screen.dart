// lib/screens/barcode_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  static const routeName = '/barcodeScanner';

  const BarcodeScannerScreen({Key? key}) : super(key: key);

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  // Remove detectDuplicates. The default behavior in v6.0.7 is to fire onDetect 
  // each time a barcode is recognized, possibly multiple times if the barcode 
  // remains in view. There's no direct param to disable duplicates in this version.
  final MobileScannerController _controller = MobileScannerController();

  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) {
    // If you prefer the new style: onDetect: (barcode, args) => ...
    // you'd also change the method signature. But for now this 
    // works if 'BarcodeCapture' is recognized in your code.
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      setState(() => _isProcessing = true);
      final code = barcodes.first.rawValue;
      if (code != null) {
        Navigator.pop(context, code);
      } else {
        // No valid code scanned, allow scanning again
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          const Align(
            alignment: Alignment.center,
            child: Icon(
              Icons.crop_free,
              size: 200,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
