import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:space_cloud/main/home/my_location/my_location.dart';

class MyLocationViewModel extends ChangeNotifier {
  final MyLocation _myLocation = MyLocation();
  Position? _currentPosition;

  MyLocationViewModel() {
    _myLocation.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
  }

  Position? get currentPosition => _currentPosition;
}