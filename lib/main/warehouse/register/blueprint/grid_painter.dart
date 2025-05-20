import 'dart:math';
import 'package:flutter/material.dart';
import 'line.dart';

class GridPainter extends CustomPainter {
  final double gridSize;
  final double width;
  final double height;
  final List<Line> lines;
  final Offset? previewStart;
  final Offset? previewEnd;
  final Set<Offset> doors;
  final Matrix4 transform;
  final Line? lineToFocus;

  GridPainter({
    this.gridSize = 50.0,
    this.width = 1000.0,
    this.height = 1000.0,
    required this.lines,
    this.previewStart,
    this.previewEnd,
    required this.doors,
    required this.transform,
    required this.lineToFocus,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.transform(transform.storage);

    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1.0;

    for (double x = 0; x <= width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }

    for (double y = 0; y <= height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3.0;

    final dotPaint = Paint()..color = Colors.transparent;

    for (final line in lines) {
      canvas.drawLine(line.start, line.end, linePaint);
      canvas.drawCircle(line.start, 5,dotPaint);
      canvas.drawCircle(line.end, 5, dotPaint);
    }

    if (previewStart != null && previewEnd != null) {
      final previewPaint = Paint()
        ..color = Colors.blue.withAlpha(75)
        ..strokeWidth = 2.0;
      canvas.drawCircle(previewStart!, 5, Paint()..color = Colors.red);
      canvas.drawLine(previewStart!, previewEnd!, previewPaint);
    }

    final doorPaint = Paint()..color = Colors.brown;

    for (final door in doors) {
      Line? nearestLine;
      double minDistance = double.infinity;

      for (final line in lines) {
        final distance = distanceToSegment(door, line.start, line.end);
        if (distance < minDistance) {
          minDistance = distance;
          nearestLine = line;
        }
      }

      if (nearestLine == null) continue;

      final dx = nearestLine.end.dx - nearestLine.start.dx;
      final dy = nearestLine.end.dy - nearestLine.start.dy;
      final angle = atan2(dy, dx);

      canvas.save();
      canvas.translate(door.dx, door.dy);
      canvas.rotate(angle);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: gridSize * 0.8,
        height: gridSize * 0.3,
      );
      canvas.drawRect(rect, doorPaint);
      canvas.restore();
    }

    if (lineToFocus != null) {
      canvas.drawCircle(lineToFocus!.start, 5, Paint()..color = Colors.red);
      canvas.drawCircle(lineToFocus!.end, 5, Paint()..color = Colors.red);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GridPainter old) {
    return old.lines != lines ||
        old.previewStart != previewStart ||
        old.previewEnd != previewEnd ||
        old.doors != doors ||
        old.transform != transform ||
        old.lineToFocus != lineToFocus;
  }

  double distanceToSegment(Offset p, Offset a, Offset b) {
    final ap = p - a;
    final ab = b - a;
    final abLenSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (abLenSq == 0.0) return (p - a).distance;

    final t = (ap.dx * ab.dx + ap.dy * ab.dy) / abLenSq;
    final clampedT = t.clamp(0.0, 1.0);
    final projection = a + ab * clampedT;
    return (p - projection).distance;
  }
}
