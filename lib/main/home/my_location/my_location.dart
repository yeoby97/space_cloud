import 'dart:async';
import 'package:geolocator/geolocator.dart';

class MyLocation {
  final _locationController = StreamController<Position>.broadcast();
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
    ).listen(_locationController.add);
  }

  Stream<Position> get positionStream => _locationController.stream;

  void dispose() {
    _positionSubscription?.cancel();
    _locationController.close();
  }
}
