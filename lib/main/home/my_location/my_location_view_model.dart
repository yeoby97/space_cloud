import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:space_cloud/main/home/my_location/my_location.dart';

class MyLocationViewModel extends ChangeNotifier {
  final MyLocation _myLocation = MyLocation();
  Position? _currentPosition;
  late final StreamSubscription<Position> _subscription;

  MyLocationViewModel() {
    _initialize();
  }

  Position? get currentPosition => _currentPosition;

  Future<void> _initialize() async {
    // 앱 시작 시 최초 위치 가져오기
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      print("초기 위치 가져오기 실패: $e");
    }

    // 위치 스트림 구독
    _subscription = _myLocation.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    notifyListeners(); // 초기 위치 반영
  }

  @override
  void dispose() {
    _subscription.cancel();
    _myLocation.dispose();
    super.dispose();
  }
}
