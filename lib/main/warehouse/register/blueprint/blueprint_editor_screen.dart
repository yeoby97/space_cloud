import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:space_cloud/main/warehouse/register/blueprint/touch_counter.dart';

import '../warehouse_register_view_model.dart';
import 'grid_painter.dart';
import 'line.dart';

class BlueprintEditorScreen extends StatefulWidget {

  const BlueprintEditorScreen({super.key,});

  @override
  State<BlueprintEditorScreen> createState() => _BlueprintEditorScreenState();
}

class _BlueprintEditorScreenState extends State<BlueprintEditorScreen> {
  late final RegisterViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = context.read<RegisterViewModel>();
  }

  late var _lines = viewModel.lines;
  late Set<Offset> _doors = viewModel.doors;
  Offset? _startPoint;
  final ValueNotifier<Offset?> _previewPoint = ValueNotifier(null);
  final double _gridSize = 30.0;
  final _transform = TransformationController();
  Line? _focusLine;

  void _onPanStart(DragStartDetails details) {
    final local = details.localPosition;
    _startPoint = snapToGrid(local);
    _previewPoint.value = local;

    Set<Offset>? doorsToRemove;
    if(_focusLine != null){
      if(_focusLine!.start == _startPoint || _focusLine!.end == _startPoint){

        doorsToRemove = _doors.where((door) {
          return distanceToSegment(door, _focusLine!.start, _focusLine!.end) < 5.0;
        }).toSet();

        if(_focusLine!.start == _startPoint){
          _startPoint = _focusLine!.end;
        } else {
          _startPoint = _focusLine!.start;
        }
        _lines.remove(_focusLine);
        _focusLine = null;
      }
    }

    setState(() {
      if(doorsToRemove != null){
        _doors.removeAll(doorsToRemove);
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final local = details.localPosition;
    _previewPoint.value = local;
  }

  void _onPanEnd(DragEndDetails details) {
    if (_startPoint != null && _previewPoint.value != null) {
      final snappedEnd = snapToGrid(_previewPoint.value!);
      final newLine = Line(_startPoint!, snappedEnd);

      final overlaps = _lines.any((existing) => linesIntersectButNotAtEndpoints(newLine, existing));
      if (overlaps) {
        setState(() {
          _startPoint = null;
          _previewPoint.value = null;
        });
        return;
      }

      setState(() {
        _lines.add(newLine);
        _startPoint = null;
        _previewPoint.value = null;
      });
    }
  }

  void _handleDoubleTap(TapDownDetails details) {
    final location = details.localPosition;
    final nearbyLine = findNearestLine(location, 15.0);
    if (nearbyLine == null) return;

    final projected = projectPointOntoSegment(location, nearbyLine.start, nearbyLine.end);
    final clamped = clampPointOnLineSegment(projected, nearbyLine.start, nearbyLine.end, 10.0);

    final existing = _doors.firstWhere(
          (door) => (door - clamped).distance < 15.0,
      orElse: () => Offset.infinite,
    );

    setState(() {
      if (existing != Offset.infinite) {
        _doors.remove(existing);
      } else {
        _doors.add(clamped);
      }
      _doors = Set.of(_doors);
    });
  }

  void _handleLongPress(LongPressStartDetails details) {
    _focusLine = null;
    final sceneTap = details.localPosition;
    final lineToRemove = _lines.firstWhere(
          (line) => distanceToSegment(sceneTap, line.start, line.end) < 10.0,
      orElse: () => Line(Offset.zero, Offset.zero),
    );

    if (lineToRemove.start == Offset.zero && lineToRemove.end == Offset.zero) return;

    final doorsToRemove = _doors.where((door) {
      return distanceToSegment(door, lineToRemove.start, lineToRemove.end) < 5.0;
    }).toSet();

    setState(() {
      _lines.remove(lineToRemove);
      _lines = List.of(_lines);
      _doors.removeAll(doorsToRemove);
      _doors = Set.of(_doors);
    });
  }

  Offset snapToGrid(Offset point) {
    final x = (point.dx / _gridSize).round() * _gridSize;
    final y = (point.dy / _gridSize).round() * _gridSize;
    return Offset(x, y);
  }

  Line? findNearestLine(Offset point, double tolerance) {
    Line? closestLine;
    double minDistance = double.infinity;

    for (final line in _lines) {
      final distance = distanceToSegment(point, line.start, line.end);
      if (distance < minDistance && distance <= tolerance) {
        minDistance = distance;
        closestLine = line;
      }
    }

    return closestLine;
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

  Offset projectPointOntoSegment(Offset p, Offset a, Offset b) {
    final ap = p - a;
    final ab = b - a;
    final abLenSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (abLenSq == 0.0) return a;

    final t = (ap.dx * ab.dx + ap.dy * ab.dy) / abLenSq;
    final clampedT = t.clamp(0.0, 1.0);
    return a + ab * clampedT;
  }

  Offset clampPointOnLineSegment(Offset p, Offset a, Offset b, double minMargin) {
    final ab = b - a;
    final length = ab.distance;
    if (length == 0) return a;

    final t = ((p - a).dx * ab.dx + (p - a).dy * ab.dy) / (length * length);
    final clampedT = t.clamp(minMargin / length, 1.0 - minMargin / length);
    return a + ab * clampedT;
  }

  bool linesIntersectButNotAtEndpoints(Line l1, Line l2) {
    final intersects = doLinesIntersect(l1.start, l1.end, l2.start, l2.end);
    if (!intersects) return false;

    final intersection = getIntersectionPoint(l1.start, l1.end, l2.start, l2.end);
    if (intersection == null) return true;

    final endpoints = {l1.start, l1.end, l2.start, l2.end};
    return !endpoints.any((e) => (e - intersection).distance < 0.001);
  }

  bool doLinesIntersect(Offset a1, Offset a2, Offset b1, Offset b2) {
    double ccw(Offset p1, Offset p2, Offset p3) {
      return (p2.dx - p1.dx) * (p3.dy - p1.dy) - (p2.dy - p1.dy) * (p3.dx - p1.dx);
    }

    return (ccw(a1, a2, b1) * ccw(a1, a2, b2) <= 0) &&
        (ccw(b1, b2, a1) * ccw(b1, b2, a2) <= 0);
  }

  Offset? getIntersectionPoint(Offset p1, Offset p2, Offset p3, Offset p4) {
    final a1 = p2.dy - p1.dy;
    final b1 = p1.dx - p2.dx;
    final c1 = a1 * p1.dx + b1 * p1.dy;

    final a2 = p4.dy - p3.dy;
    final b2 = p3.dx - p4.dx;
    final c2 = a2 * p3.dx + b2 * p3.dy;

    final delta = a1 * b2 - a2 * b1;
    if (delta.abs() < 1e-6) return null;

    final x = (b2 * c1 - b1 * c2) / delta;
    final y = (a1 * c2 - a2 * c1) / delta;
    return Offset(x, y);
  }

  void _focus(TapUpDetails details){
    final location = details.localPosition;
    final lineToFocus = _lines.firstWhere(
          (line) => distanceToSegment(location, line.start, line.end) < 10.0,
      orElse: () => Line(Offset.zero, Offset.zero),
    );
    setState(() {
      _focusLine = lineToFocus;
    });
    return;
  }

  @override
  Widget build(BuildContext context) {
    final fingerCount = context.watch<TouchCounterNotifier>().state;
    final notifier = context.read<TouchCounterNotifier>();
    final canDraw = fingerCount <= 1;
    final scale = _transform.value.getMaxScaleOnAxis();
    final scaledSize = 1000 / scale;

    return WillPopScope(
      onWillPop: () async {
        viewModel.drawChange(false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: Text('건물 도면 작성')),
        body: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => notifier.onPointerDown(),
          onPointerUp: (_) => notifier.onPointerUp(),
          onPointerCancel: (_) => notifier.onPointerCancel(),
          child: Center(
            child: SizedBox(
              width: 1000,
              height: 1000,
              child: ClipRect(
                child: InteractiveViewer(
                  panEnabled: !canDraw,
                  scaleEnabled: !canDraw,
                  minScale: 0.5,
                  maxScale: 3.0,
                  constrained: false,
                  clipBehavior: Clip.none,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapUp: _focus,
                    onPanStart: canDraw ? _onPanStart : null,
                    onPanUpdate: canDraw ? _onPanUpdate : null,
                    onPanEnd: canDraw ? _onPanEnd : null,
                    onDoubleTapDown: _handleDoubleTap,
                    onLongPressStart: _handleLongPress,
                    child: ValueListenableBuilder<Offset?>(
                      valueListenable: _previewPoint,
                      builder: (context, preview, _) => CustomPaint(
                        size: Size(scaledSize, scaledSize),
                        painter: GridPainter(
                          gridSize: _gridSize,
                          lines: _lines,
                          previewStart: _startPoint,
                          previewEnd: preview,
                          doors: _doors,
                          transform: _transform.value,
                          lineToFocus: _focusLine,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}