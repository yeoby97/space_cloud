import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_places_hoc081098/google_maps_webservice_places.dart';

const String kGoogleApiKey = 'AIzaSyAuhd1aQTSgjtgnydP3_wgD3SDD2QD-VGU';
final GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Prediction> _predictions = [];
  LatLng? selectedLatLng;
  String? selectedAddress;
  Timer? _debounce;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 텍스트 박스
              Container(
                width: 500,
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
                    hintText: "Search your location",
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                  ),
                ),
              ),
              SizedBox(height: 10),

              // 자동완성 리스트
              if (_predictions.isNotEmpty)
                Expanded(
                  child: ListView.separated(
                    itemCount: _predictions.length,
                    separatorBuilder: (context, index) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final prediction = _predictions[index];
                      return ListTile(
                        leading: Icon(Icons.location_on),
                        title: Text(prediction.description ?? ""),
                        onTap: () => _selectPrediction(prediction),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onChanged(String value) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (value.isEmpty) {
        setState(() {
          _predictions = [];
        });
        return;
      }

      final response = await _places.autocomplete(
        value,
        language: 'ko',
        components: [Component(Component.country, "kr")],
      );

      if (response.isOkay) {
        setState(() {
          _predictions = response.predictions;
        });
      } else {
        print("Autocomplete error: ${response.errorMessage}");
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel(); // 메모리 누수 방지
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectPrediction(Prediction p) async {
    final detail = await _places.getDetailsByPlaceId(p.placeId!);
    final lat = detail.result.geometry!.location.lat;
    final lng = detail.result.geometry!.location.lng;
    final address = p.description ?? "";

    setState(() {
      selectedLatLng = LatLng(lat, lng);
      selectedAddress = address;
      _controller.text = address;
      _predictions = [];
    });

    Navigator.of(context).pop({
      "location": selectedLatLng,
      "address": selectedAddress,
    });
  }
}
