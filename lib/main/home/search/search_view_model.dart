// TODO : 최적화 및 상태 최상단화

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_places_hoc081098/google_maps_webservice_places.dart';
import 'package:geolocator/geolocator.dart';

class SearchViewModel extends ChangeNotifier {
  final GoogleMapsPlaces _places;
  final TextEditingController controller = TextEditingController();

  List<Prediction> predictions = [];
  List<Map<String, dynamic>> nearbyPlaces = [];
  bool isLoading = false;

  static const double _maxDistanceMeters = 10000;
  Timer? _debounce;

  SearchViewModel(String apiKey) : _places = GoogleMapsPlaces(apiKey: apiKey);

  void onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (value.trim().isEmpty) {
        predictions.clear();
        await loadNearbyWarehouses();
        notifyListeners();
        return;
      }

      final response = await _places.autocomplete(value, language: 'ko', components: [Component(Component.country, "kr")]);
      if (response.isOkay) {
        predictions = response.predictions;
      }

      await _loadNearbyFromSearch(value);
      notifyListeners();
    });
  }

  Future<void> loadNearbyWarehouses() async {
    isLoading = true;
    notifyListeners();

    final location = await _getCurrentLocation();
    if (location != null) {
      await _fetchWarehousesNearby(location);
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadNearbyFromSearch(String query) async {
    final search = await _places.searchByText(query);
    if (search.isOkay && search.results.isNotEmpty) {
      final result = search.results.first.geometry!.location;
      await _fetchWarehousesNearby(LatLng(result.lat, result.lng));
    }
  }

  Future<void> _fetchWarehousesNearby(LatLng base) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('warehouse')
        .get();

    final filterList = <Map<String, dynamic>>[];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      // data 안에 lat, lng가 있는지 확인 없으면 null 반환
      if (!data.containsKey('lat') || !data.containsKey('lng')) return null;


      // 거리값 계산
      final distance = Geolocator.distanceBetween(
        base.latitude,
        base.longitude,
        data['lat'],
        data['lng'],
      );

      // 일정 거리 넘으면 null 반환
      if (distance > _maxDistanceMeters) return null;

      // 일정 거리 안에 있으면

      final warehousesSnapshot = await FirebaseFirestore.instance
          .collection('warehouse')
          .doc(doc.id)
          .collection('warehouses')
          .get();

      for (var warehouseDoc in warehousesSnapshot.docs) {
        final warehouseData = warehouseDoc.data();

        filterList.add({
          'name': warehouseData['address'],
          'distance': distance,
          'latLng': LatLng(warehouseData['lat'], warehouseData['lng']),
        });
      }

      // 반환해줄 정보
      //   return {
      //     'name': data['address'] ?? doc.id,
      //     'distance': distance,
      //     'latLng': LatLng(data['lat'], data['lng']),
      //   };
      // }
      //
      // filtered.sort((a, b) => a['distance'].compareTo(b['distance']));
      // nearbyPlaces = filtered;
    }
    filterList.sort((a, b) => a['distance'].compareTo(b['distance']));
    nearbyPlaces = filterList;
  }

  Future<LatLng?> _getCurrentLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      final result = await Geolocator.requestPermission();
      if (result != LocationPermission.whileInUse && result != LocationPermission.always) {
        return null;
      }
    }

    final pos = await Geolocator.getCurrentPosition();
    return LatLng(pos.latitude, pos.longitude);
  }

  void disposeDebounce() {
    _debounce?.cancel();
    controller.dispose();
    super.dispose();
  }
}