import 'package:flutter/material.dart';

class TouchCounterNotifier extends ChangeNotifier {
  int _count = 0;

  int get state => _count;
  bool get canDraw => _count == 1;

  void onPointerDown() {
    _count++;
    notifyListeners();
  }

  void onPointerUp() {
    _count = (_count - 1).clamp(0, 10);

  }

  void onPointerCancel() {
    _count = 0;
    notifyListeners();
  }

  void reset() {
    _count = 0;
    notifyListeners();
  }
}
