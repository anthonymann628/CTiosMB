// lib/widgets/signature_pad.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A simple signature pad where the user can draw with their finger.
/// When done, call [onDone] passing the final `ui.Image`.
class SignaturePad extends StatefulWidget {
  /// Called when the user taps 'Done', passing the captured `ui.Image`.
  final Future<void> Function(ui.Image) onDone;

  const SignaturePad({
    Key? key,
    required this.onDone,
  }) : super(key: key);

  @override
  _SignaturePadState createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  /// Each stroke is a list of [Offset] points.
  final List<List<Offset>> _strokes = [];

  /// A global key so we can convert the signature widget to an image on 'Done'.
  final GlobalKey _signatureKey = GlobalKey();

  void _onPanStart(DragStartDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final point = box.globalToLocal(details.globalPosition);
    setState(() {
      _strokes.add([point]);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final point = box.globalToLocal(details.globalPosition);
    setState(() {
      _strokes.last.add(point);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // Stroke finished, do nothing special here
  }

  void _clear() {
    setState(() {
      _strokes.clear();
    });
  }

  /// Called when the user taps the 'Done' button.
  /// Converts the signature widget to a `ui.Image` then calls [widget.onDone].
  Future<void> _finish() async {
    try {
      final boundary = _signatureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        // If we can't find the boundary, we can't create an image
        return;
      }
      // 2.0 pixel ratio for slightly higher resolution
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      await widget.onDone(image);
    } catch (e) {
      // If capturing fails, we might do an empty pop or show an error
    }
  }

  @override
  Widget build(BuildContext context) {
    // A RepaintBoundary so we can convert it to an image
    return RepaintBoundary(
      key: _signatureKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Signature Pad'),
        ),
        body: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: CustomPaint(
            painter: _SignaturePainter(_strokes),
            child: Container(
              color: Colors.white,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _clear,
                  child: const Text('Clear'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _finish,
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A custom painter that draws all strokes.
class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final stroke in strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
      // If it's just a single point, draw a small dot
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) {
    // Repaint whenever strokes change
    return oldDelegate.strokes != strokes;
  }
}
