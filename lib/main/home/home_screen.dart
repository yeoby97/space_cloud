import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'my_location_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, Marker> _markers = {}; // 창고들 마커로 표기
  late GoogleMapController _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Map Example")),
      body: Stack(
        children: [
          Consumer<MyLocationViewModel>(
            builder: (context, viewModel, child) {
              final currentPosition = viewModel.currentPosition;

              if (currentPosition == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return showGoogleMap(currentPosition);
            },
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FloatingActionButton(
                onPressed: () {
                  _goToCurrentLocation();
                },
                child: const Icon(Icons.location_searching),
              ),
            ),
          ),
        ]
      ),
    );
  }

  GoogleMap showGoogleMap(Position currentPosition) {
    return GoogleMap(
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      initialCameraPosition: CameraPosition(
        target: LatLng(currentPosition.latitude, currentPosition.longitude),
        zoom: 18,
      ),
      onMapCreated: (controller) {
        _mapController = controller; // GoogleMapController 초기화
      },
      markers: _markers.values.toSet(),
    );
  }

  void _goToCurrentLocation() async {
    final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    _mapController.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        bearing: 0,
        target: LatLng(currentPosition.latitude, currentPosition.longitude),
        zoom: 18.0,
      ),
    ));
  }
}
