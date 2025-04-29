// TODO : 최적화 및 상태 최상단화

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:space_cloud/main/home/my_location/my_location.dart';

class MyLocationViewModel extends ChangeNotifier {
  final MyLocation _myLocation = MyLocation();
  Position? _currentPosition;
  late final StreamSubscription<Position> _subscription;

  MyLocationViewModel() {
    _subscription = _myLocation.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
  }

  Position? get currentPosition => _currentPosition;

  @override
  void dispose() {
    _subscription.cancel();
    _myLocation.dispose();
    super.dispose();
  }
}
