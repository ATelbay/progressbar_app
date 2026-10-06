import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

import '../theme.dart';

/// A QR code on a light plate. The plate stays light in the dark theme too:
/// cameras read dark squares on a light ground.
class QrCodeView extends StatelessWidget {
  const QrCodeView({
    super.key,
    required this.data,
    required this.label,
    this.size = 176,
  });

  final String data;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: label,
    child: Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(PbSpace.s3),
      decoration: BoxDecoration(
        color: PbColors.dawn.surface,
        borderRadius: BorderRadius.circular(PbRadius.md),
      ),
      child: CustomPaint(
        painter: _QrPainter(
          QrImage(QrCode(payload: QrPayload.fromString(data))),
          PbColors.dawn.ink,
        ),
      ),
    ),
  );
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.image, this.color);

  final QrImage image;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    final count = image.moduleCount;
    // Whole pixels per square, centred: fractional squares blur the edges.
    final step = (size.shortestSide / count).floorToDouble();
    final offset = (size.shortestSide - step * count) / 2;
    for (var row = 0; row < count; row++) {
      for (var col = 0; col < count; col++) {
        if (image.isDark(row, col)) {
          canvas.drawRect(
            Rect.fromLTWH(offset + col * step, offset + row * step, step, step),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) =>
      old.image != image || old.color != color;
}
