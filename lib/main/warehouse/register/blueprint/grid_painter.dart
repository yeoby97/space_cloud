import 'package:flutter/material.dart';

import 'line.dart';

class GridPainter extends CustomPainter {
  final double gridSize;
  final List<Line> lines;
  final Offset? previewStart;
  final Offset? previewEnd;

  GridPainter({
    required this.gridSize,
    required this.lines,
    this.previewStart,
    this.previewEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1.0;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3.0;

    final dotPaint = Paint()..color = Colors.red;

    // 이미 그린 선들
    for (final line in lines) {
      canvas.drawLine(line.start, line.end, linePaint);
      canvas.drawCircle(line.start, 5, dotPaint);
      canvas.drawCircle(line.end, 5, dotPaint);
    }

    // 프리뷰 선
    if (previewStart != null && previewEnd != null) {
      final previewPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..strokeWidth = 2.0;
      canvas.drawLine(previewStart!, previewEnd!, previewPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter old) {
    return old.lines != lines ||
        old.previewStart != previewStart ||
        old.previewEnd != previewEnd;
  }
}