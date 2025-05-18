import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ✅ provider 패키지로 변경
import 'package:space_cloud/main/warehouse/register/blueprint/touch_counter.dart';

import 'grid_painter.dart';
import 'line.dart';

class BlueprintEditorScreen extends StatefulWidget {
  const BlueprintEditorScreen({super.key});
  @override
  State<BlueprintEditorScreen> createState() => _BlueprintEditorScreenState();
}

class _BlueprintEditorScreenState extends State<BlueprintEditorScreen> {
  List<Line> _lines = [];
  Offset? _startPoint;
  Offset? _previewPoint;
  final double _gridSize = 50.0;
  final _transform = TransformationController();

  Offset snapToGrid(Offset point) {
    final x = (point.dx / _gridSize).round() * _gridSize;
    final y = (point.dy / _gridSize).round() * _gridSize;
    return Offset(x, y);
  }

  void _onPanStart(DragStartDetails details) {
    final local = details.localPosition;
    setState(() {
      _startPoint = snapToGrid(local);
      _previewPoint = local;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _previewPoint = details.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_startPoint != null && _previewPoint != null) {
      final snappedEnd = snapToGrid(_previewPoint!);
      setState(() {
        _lines.add(Line(_startPoint!, snappedEnd));
        _startPoint = null;
        _previewPoint = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fingerCount = context.watch<TouchCounterNotifier>().state;
    final notifier = context.read<TouchCounterNotifier>();
    final canDraw = fingerCount <= 1;

    return Scaffold(
      appBar: AppBar(title: Text('건물 도면 작성')),
      body: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => notifier.onPointerDown(),
        onPointerUp: (_) => notifier.onPointerUp(),
        onPointerCancel: (_) => notifier.onPointerCancel(),
        child: InteractiveViewer(
          transformationController: _transform,
          panEnabled: !canDraw,
          scaleEnabled: !canDraw,
          minScale: 0.5,
          maxScale: 3.0,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: canDraw ? _onPanStart : null,
            onPanUpdate: canDraw ? _onPanUpdate : null,
            onPanEnd: canDraw ? _onPanEnd : null,
            child: CustomPaint(
              size: const Size(1000, 1000),
              painter: GridPainter(
                gridSize: _gridSize,
                lines: _lines,
                previewStart: _startPoint,
                previewEnd: _previewPoint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
