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
    final snapshot = await FirebaseFirestore.instance.collection('warehouse').get();

    final filtered = snapshot.docs.map((doc) {
      final data = doc.data();
      if (!data.containsKey('lat') || !data.containsKey('lng')) return null;

      final distance = Geolocator.distanceBetween(
        base.latitude,
        base.longitude,
        data['lat'],
        data['lng'],
      );

      if (distance > _maxDistanceMeters) return null;

      return {
        'name': data['address'] ?? doc.id,
        'distance': distance,
        'latLng': LatLng(data['lat'], data['lng']),
      };
    }).whereType<Map<String, dynamic>>().toList();

    filtered.sort((a, b) => a['distance'].compareTo(b['distance']));
    nearbyPlaces = filtered;
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