import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:space_cloud/main/home/search/search_screen.dart';

import '../../data/warehouse.dart';
import '../warehouse/warehouse_management.dart';
import 'bottom_sheet/custom_bottom_sheet.dart';
import 'my_location/my_location_view_model.dart';

class HomeScreen extends StatefulWidget {
  final ValueNotifier<bool> isBottomSheetOpenNotifier;
  const HomeScreen({super.key, required this.isBottomSheetOpenNotifier});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Marker> _markers = [];
  Warehouse? _selectedWarehouse;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadWarehouseMarkers();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildGoogleMap(),
          _buildSearchBox(),
          SafeArea(child: _buildLocationButton()),
          if (_selectedWarehouse != null)
            CustomBottomSheet(
              warehouse: _selectedWarehouse!,
              isOpenNotifier: widget.isBottomSheetOpenNotifier,
              onClose: () {
                widget.isBottomSheetOpenNotifier.value = false;
                setState(() => _selectedWarehouse = null);
              },
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WarehouseManagement(warehouse: _selectedWarehouse!),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGoogleMap() {
    return Consumer<MyLocationViewModel>(
      builder: (context, viewModel, _) {
        final position = viewModel.currentPosition;

        if (position == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return GoogleMap(
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          initialCameraPosition: CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16,
          ),
          onMapCreated: (controller) {
            _mapController ??= controller;
          },
          markers: Set<Marker>.from(_markers),
        );
      },
    );
  }

  Widget _buildLocationButton() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FloatingActionButton(
          shape: const CircleBorder(),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black.withAlpha(150),
          onPressed: _goToCurrentLocation,
          child: const Icon(Icons.location_searching),
        ),
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16,
        ),
      ),
    );
  }

  Future<void> _onSearchTap() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );

    final LatLng? location = result?['location'];
    if (location != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 16),
        ),
      );
    }
  }

  Future<void> _loadWarehouseMarkers() async {
    final snapshot = await FirebaseFirestore.instance.collection('warehouse').get();

    final markers = snapshot.docs.map((doc) {
      final warehouse = Warehouse.fromDoc(doc);

      return Marker(
        markerId: MarkerId(warehouse.id),
        position: LatLng(warehouse.lat, warehouse.lng),
        infoWindow: InfoWindow(title: warehouse.address),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        onTap: () {
          widget.isBottomSheetOpenNotifier.value = true;
          setState(() => _selectedWarehouse = warehouse);
        },
      );
    }).toList();

    _markers
      ..clear()
      ..addAll(markers);
    setState(() {});
  }

  Widget _buildSearchBox() {
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: GestureDetector(
            onTap: _onSearchTap,
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(3, 3),
                  ),
                ],
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Icon(Icons.map),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '장소나 위치를 검색하세요.',
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.search),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}