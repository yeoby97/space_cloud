import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_places_hoc081098/google_maps_webservice_places.dart';
import 'package:geolocator/geolocator.dart';

const String kGoogleApiKey = 'AIzaSyAuhd1aQTSgjtgnydP3_wgD3SDD2QD-VGU';
final GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

class SearchScreen extends StatefulWidget {
  final GoogleMapController? mapController;

  const SearchScreen({super.key, this.mapController});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Prediction> _predictions = [];
  final List<Map<String, dynamic>> _nearbyPlaces = [];
  Timer? _debounce;
  bool _isLoading = false;

  static const double maxDistanceInMeters = 10000; // 10km

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: Offset(3, 3),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: TextField(
                  controller: _controller,
                  onChanged: _onChanged,
                  decoration: InputDecoration(
                    hintText: "장소나 위치를 검색하세요.",
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              if (_predictions.isNotEmpty)
                Expanded(
                  child: ListView.separated(
                    itemCount: _predictions.length,
                    separatorBuilder: (_, __) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final prediction = _predictions[index];
                      return ListTile(
                        leading: Icon(Icons.location_on),
                        title: Text(prediction.description ?? ""),
                        onTap: () => _onPlaceSelected(prediction),
                      );
                    },
                  ),
                ),

              if (_nearbyPlaces.isNotEmpty || _isLoading)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "📦 10km 이내 추천 창고",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator()),
                      if (!_isLoading)
                        Expanded(
                          child: ListView.separated(
                            itemCount: _nearbyPlaces.length,
                            separatorBuilder: (_, __) => Divider(height: 1),
                            itemBuilder: (context, index) {
                              final place = _nearbyPlaces[index];
                              return ListTile(
                                leading: Icon(Icons.warehouse),
                                title: Text(place['name']),
                                subtitle: Text("${(place['distance'] / 1000).toStringAsFixed(2)} km 거리"),
                                onTap: () => _onWarehouseSelected(place),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadInitialNearbyPlaces();
  }

  Future<void> _loadInitialNearbyPlaces() async {
    final currentLocation = await _getCurrentLocation();
    if (currentLocation != null) {
      await _fetchNearbyPlaces(currentLocation);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (value.trim().isEmpty) {
        setState(() {
          _predictions.clear();
        });

        final currentLocation = await _getCurrentLocation();
        if (currentLocation != null) {
          await _fetchNearbyPlaces(currentLocation);
        } else {
          print("현재 위치를 가져올 수 없습니다.");
          setState(() {
            _nearbyPlaces.clear();
          });
        }
        return;
      }

      setState(() => _isLoading = true);

      final response = await _places.autocomplete(
        value,
        language: 'ko',
        components: [Component(Component.country, "kr")],
      );

      if (response.isOkay) {
        setState(() {
          _predictions
            ..clear()
            ..addAll(response.predictions);
        });
      }

      await _updateNearbyFromInput(value);
    });
  }

  Future<void> _updateNearbyFromInput(String input) async {
    try {
      final search = await _places.searchByText(input);
      if (search.status == 'OK' && search.results.isNotEmpty) {
        final result = search.results.first;
        final lat = result.geometry!.location.lat;
        final lng = result.geometry!.location.lng;
        final base = LatLng(lat, lng);
        await _fetchNearbyPlaces(base);
      }
    } catch (e) {
      print("주소 검색 실패: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchNearbyPlaces(LatLng base) async {
    setState(() => _isLoading = true);

    final snapshot = await FirebaseFirestore.instance.collection('warehouse').get();

    final places = snapshot.docs.map((doc) {
      final data = doc.data();
      if (!data.containsKey('lat') || !data.containsKey('lng')) return null;

      final lat = data['lat'];
      final lng = data['lng'];
      final address = data['address'] ?? doc.id;

      final distance = Geolocator.distanceBetween(
        base.latitude, base.longitude, lat, lng,
      );

      if (distance > maxDistanceInMeters) return null;

      return {
        'name': address,
        'distance': distance,
        'latLng': LatLng(lat, lng),
      };
    }).whereType<Map<String, dynamic>>().toList();

    places.sort((a, b) => a['distance'].compareTo(b['distance']));

    setState(() {
      _nearbyPlaces
        ..clear()
        ..addAll(places);
      _isLoading = false;
    });
  }

  Future<LatLng?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }
    }

    final position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  void _onPlaceSelected(Prediction prediction) async {
    final detail = await _places.getDetailsByPlaceId(prediction.placeId!);
    final lat = detail.result.geometry!.location.lat;
    final lng = detail.result.geometry!.location.lng;

    final target = LatLng(lat, lng);
    widget.mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 15));

    Navigator.of(context).pop({
      "location": target,
      "address": prediction.description,
    });
  }

  void _onWarehouseSelected(Map<String, dynamic> place) {
    final LatLng location = place['latLng'];
    widget.mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 15));

    Navigator.of(context).pop({
      "location": location,
      "address": place['name'],
    });
  }
}
