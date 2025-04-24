import 'package:flutter/material.dart';

class BarcodeScannerViewfinder extends StatelessWidget {
  final double width;
  final double height;
  final Color borderColor;
  final double borderWidth;
  final double cornerLength;

  const BarcodeScannerViewfinder({
    Key? key,
    this.width = 250,
    this.height = 250,
    this.borderColor = Colors.white,
    this.borderWidth = 4.0,
    this.cornerLength = 40.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _ViewfinderPainter(borderColor, borderWidth, cornerLength),
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;

  _ViewfinderPainter(this.color, this.strokeWidth, this.cornerLength);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    double w = size.width;
    double h = size.height;
    // Top-left corner
    canvas.drawLine(Offset(0, 0), Offset(cornerLength, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(0, cornerLength), paint);
    // Top-right corner
    canvas.drawLine(Offset(w, 0), Offset(w - cornerLength, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, cornerLength), paint);
    // Bottom-left corner
    canvas.drawLine(Offset(0, h), Offset(cornerLength, h), paint);
    canvas.drawLine(Offset(0, h), Offset(0, h - cornerLength), paint);
    // Bottom-right corner
    canvas.drawLine(Offset(w, h), Offset(w - cornerLength, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
