// lib/screens/signature_screen.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';

class SignatureScreen extends StatefulWidget {
  static const routeName = '/signature';

  const SignatureScreen({Key? key}) : super(key: key);

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );

  Future<void> _saveSignature() async {
    try {
      if (_controller.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No signature drawn')));
        return;
      }

      final ui.Image? image = await _controller.toImage();
      if (image == null) {
        // handle error
        return;
      }
      // now image is non-null
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'signature_${DateTime.now().millisecondsSinceEpoch}.png';
      final path = '${dir.path}/$fileName';
      final file = File(path);
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;
      Navigator.pop(context, path);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error saving signature: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Signature'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Signature(
              controller: _controller,
              backgroundColor: Colors.grey[200]!,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _controller.clear(),
                child: const Text('Clear'),
              ),
              ElevatedButton(
                onPressed: _saveSignature,
                child: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
