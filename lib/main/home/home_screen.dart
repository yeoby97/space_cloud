import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:space_cloud/main/home/search_screen.dart';

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
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    _loadWarehouseMarkers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _googleMap(),
          _SearchBox(onTap: _onTap),
          SafeArea(child: _floatingButton()),
          if (_selectedWarehouse != null)
            CustomBottomSheet(
              warehouse: _selectedWarehouse!,
              isOpenNotifier: widget.isBottomSheetOpenNotifier,
              onClose: () {
                widget.isBottomSheetOpenNotifier.value = false;
                setState(() {
                  _selectedWarehouse = null;
                });
              },
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => WarehouseManagement(warehouse: _selectedWarehouse!),
                ));
              },
            ),
        ],
      ),
    );
  }

  Consumer<MyLocationViewModel> _googleMap() {
    return Consumer<MyLocationViewModel>(
      builder: (context, viewModel, child) {
        final currentPosition = viewModel.currentPosition;

        if (currentPosition == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return GoogleMap(
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          initialCameraPosition: CameraPosition(
            target: LatLng(currentPosition.latitude, currentPosition.longitude),
            zoom: 16,
          ),
          onMapCreated: (controller) => _mapController = controller,
          markers: Set<Marker>.from(_markers),
        );
      },
    );
  }

  Align _floatingButton() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FloatingActionButton(
          shape: const CircleBorder(),
          foregroundColor: Colors.black.withAlpha(150),
          backgroundColor: Colors.white,
          onPressed: _goToCurrentLocation,
          child: const Icon(Icons.location_searching),
        ),
      ),
    );
  }

  void _goToCurrentLocation() async {
    final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    _mapController.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        bearing: 0,
        target: LatLng(currentPosition.latitude, currentPosition.longitude),
        zoom: 16.0,
      ),
    ));
  }

  void _onTap() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );

    if (result?['location'] != null) {
      _mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          bearing: 0,
          target: result['location'],
          zoom: 16.0,
        ),
      ));
    }
  }

  Future<void> _loadWarehouseMarkers() async {
    final snapshot =
    await FirebaseFirestore.instance.collection('warehouse').get();

    final markers = <Marker>[];

    for (var doc in snapshot.docs) {
      final warehouse = Warehouse.fromDoc(doc);

      final marker = Marker(
        markerId: MarkerId(warehouse.id),
        position: LatLng(warehouse.lat, warehouse.lng),
        infoWindow: InfoWindow(title: warehouse.address),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        onTap: () {
          widget.isBottomSheetOpenNotifier.value = true;
          setState(() {
            _selectedWarehouse = warehouse;
          });
        },
      );
      markers.add(marker);
    }

    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
  }
}

class _SearchBox extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBox({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: GestureDetector(
            onTap: onTap,
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
                  children: [
                    const Icon(Icons.map),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          '장소나 위치를 검색하세요.',
                          style: TextStyle(
                            color: Colors.black.withAlpha(100),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const Icon(Icons.search),
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
