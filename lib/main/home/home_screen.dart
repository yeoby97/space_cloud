// TODO : 최적화 및 상태 최상단화

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:space_cloud/main/home/bottom_sheet/favorite/favorite_button.dart';
import 'package:space_cloud/main/home/bottom_sheet/favorite/favorite_service.dart';
import 'package:space_cloud/main/home/bottom_sheet/favorite/favorite_view_model.dart';

import '../warehouse/warehouse_management.dart';
import 'bottom_sheet/custom_bottom_sheet.dart';
import 'home_view_model.dart';
import 'my_location/my_location_view_model.dart';
import 'search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueNotifier<bool> isBottomSheetOpenNotifier;
  const HomeScreen({super.key, required this.isBottomSheetOpenNotifier});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().loadWarehouseMarkers(
        onTapWarehouse: (warehouse) {
          widget.isBottomSheetOpenNotifier.value = true;
        },
      );
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationVM = context.watch<MyLocationViewModel>();
    final homeVM = context.watch<HomeViewModel>();
    final position = locationVM.currentPosition;
    final selectedWarehouse = homeVM.selectedWarehouse;

    return Scaffold(
      body: Stack(
        children: [
          if (position == null)
            const Center(child: CircularProgressIndicator())
          else
            GoogleMap(
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              initialCameraPosition: CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 16,
              ),
              onMapCreated: (controller) => _mapController ??= controller,
              markers: Set<Marker>.from(homeVM.markers),
            ),
          _buildSearchBox(),
          SafeArea(child: _buildLocationButton()),
          if (selectedWarehouse != null)
           ChangeNotifierProvider(
             create: (_) => FavoriteViewModel(
               favoriteService: FavoriteService(),
             ),
             child:  CustomBottomSheet(
               warehouse: selectedWarehouse,
               isOpenNotifier: widget.isBottomSheetOpenNotifier,
               onClose: () {
                 widget.isBottomSheetOpenNotifier.value = false;
                 homeVM.clearSelectedWarehouse();
               },
               onTap: () {
                 Navigator.of(context).push(
                   MaterialPageRoute(
                     builder: (_) => WarehouseManagement(
                       warehouse: selectedWarehouse,
                     ),
                   ),
                 );
               },
             ),
           ),
        ],
      ),
    );
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
              child: const Padding(
                padding: EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
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
}
