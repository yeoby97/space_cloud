import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:space_cloud/main/home/my_location/my_location.dart';

class MyLocationViewModel extends ChangeNotifier {
  final MyLocation _myLocation = MyLocation();
  Position? _currentPosition;
  StreamSubscription<Position>? _subscription;

  MyLocationViewModel() {
    _startListening();
  }

  Position? get currentPosition => _currentPosition;

  void _startListening() {
    _subscription?.cancel();
    _subscription = _myLocation.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
  }

  void reset() {
    _subscription?.cancel();
    _currentPosition = null;
    _startListening();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _myLocation.dispose();
    super.dispose();
  }
}
