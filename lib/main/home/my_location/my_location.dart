import 'dart:async';
import 'package:geolocator/geolocator.dart';

class MyLocation {
  final StreamController<Position> _locationController =
  StreamController<Position>.broadcast();

  StreamSubscription<Position>? _positionSubscription;

  MyLocation() {
    _startTracking();
  }

  void _startTracking() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      _locationController.add(position);
    });
  }

  Stream<Position> get positionStream => _locationController.stream;

  void dispose() {
    _positionSubscription?.cancel();
    _locationController.close();
  }
}
