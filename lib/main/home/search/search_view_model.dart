// TODO : 최적화 및 상태 최상단화 및 보안 강화

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class SearchViewModel extends ChangeNotifier {
  final String _clientId;
  final String _clientSecret;
  final TextEditingController controller = TextEditingController();

  List<Map<String, dynamic>> predictions = [];
  List<Map<String, dynamic>> nearbyPlaces = [];
  bool isLoading = false;

  static const double _maxDistanceMeters = 10000;
  Timer? _debounce;

  SearchViewModel(this._clientId, this._clientSecret);

  void onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (value.trim().isEmpty) {
        predictions.clear();
        await loadNearbyWarehouses();
        notifyListeners();
        return;
      }

      await _fetchNaverPredictions(value);
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

  Future<void> _fetchNaverPredictions(String query) async {
    final encodedQuery = Uri.encodeQueryComponent(query);
    final uri = Uri.parse(
        'https://openapi.naver.com/v1/search/local.json?query=$encodedQuery&display=5'
    );

    try {
      final response = await http.get(uri, headers: {
        'X-Naver-Client-Id': _clientId,
        'X-Naver-Client-Secret': _clientSecret,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List;
        print(data);
        predictions = items.map((item) {
          return {
            'title': _stripHtml(item['title']),
            'address': item['address'],
            'mapx': double.tryParse(item['mapx']) ?? 0.0,
            'mapy': double.tryParse(item['mapy']) ?? 0.0,
          };
        }).toList();
      } else {
        predictions = [];
      }
    } catch (_) {
      predictions = [];
    }
  }

  Future<void> _fetchWarehousesNearby(NLatLng base) async {
    final snapshot =
    await FirebaseFirestore.instance.collection('warehouse').get();

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
        'latLng': NLatLng(data['lat'], data['lng']),
      };
    }).whereType<Map<String, dynamic>>().toList();

    filtered.sort((a, b) => a['distance'].compareTo(b['distance']));
    nearbyPlaces = filtered;
  }

  Future<NLatLng?> _getCurrentLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      final result = await Geolocator.requestPermission();
      if (result != LocationPermission.whileInUse &&
          result != LocationPermission.always) {
        return null;
      }
    }

    final pos = await Geolocator.getCurrentPosition();
    return NLatLng(pos.latitude, pos.longitude);
  }

  void disposeDebounce() {
    _debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  String _stripHtml(String htmlText) {
    return htmlText.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  Map<String, double> convertTM128toWGS84(double mapx, double mapy) {
    final lng = mapx * 1e-7;
    final lat = mapy * 1e-7;
    return {'lat': lat, 'lng': lng};
  }
}