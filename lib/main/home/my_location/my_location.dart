import 'dart:async';
import 'package:geolocator/geolocator.dart';

class MyLocation {
  final StreamController<Position> _locationController =
      StreamController<Position>.broadcast();

  MyLocation() {
    _startTracking();
  }

  void _startTracking() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // 5m 이동 시 업데이트
      ),
    ).listen((Position position) {
      _locationController.add(position);
    });
  }

  Stream<Position> get positionStream => _locationController.stream;
}