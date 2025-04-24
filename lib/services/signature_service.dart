import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/signature.dart';
import 'storage_service.dart';
import '../widgets/signature_pad.dart';

class SignatureService {
  static Future<Signature?> captureSignature(BuildContext context) async {
    // We push the SignaturePad widget that returns a ui.Image in 'onDone'
    // We'll do a MaterialPageRoute that returns the PNG bytes
    final ui.Image? signatureImage = await Navigator.push<ui.Image?>(
      context,
      MaterialPageRoute(
        builder: (_) => SignaturePad(
          onDone: (ui.Image image) async {
            Navigator.of(context).pop(image);
          },
        ),
      ),
    );

    if (signatureImage == null) {
      // user canceled or no signature
      return null;
    }

    // Convert to PNG bytes
    final byteData = await signatureImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return null;
    }
    final bytes = byteData.buffer.asUint8List();

    // Save signature
    final file = await StorageService.saveBytes(bytes, StorageFolder.signature);
    return Signature(filePath: file.path);
  }
}
