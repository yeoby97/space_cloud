import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:space_cloud/main/home/bottom_sheet/custom_bottom_sheet.dart';
import 'package:space_cloud/main/home/home_view_model.dart';
import 'package:space_cloud/main/home/my_location/my_location_view_model.dart';
import 'package:space_cloud/main/home/search/search_screen.dart';
import 'package:space_cloud/main/warehouse/warehouse_management.dart';

import '../../data/warehouse.dart';

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
      final homeVM = context.read<HomeViewModel>();
      homeVM.updateOnTapCallback((_) {
        widget.isBottomSheetOpenNotifier.value = true;
      });
      homeVM.startListeningToWarehouses();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBackPressed();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Consumer2<MyLocationViewModel, HomeViewModel>(
              builder: (context, locationVM, homeVM, child) {
                final position = locationVM.currentPosition;
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
                    _mapController = controller;
                  },
                  markers: Set<Marker>.from(homeVM.markers),
                );
              },
            ),
            _buildSearchBox(),
            SafeArea(child: _buildLocationButton()),

            ValueListenableBuilder<bool>(
              valueListenable: widget.isBottomSheetOpenNotifier,
              builder: (_, isOpen, __) {
                if (!isOpen) return const SizedBox.shrink();
                return Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      widget.isBottomSheetOpenNotifier.value = false;
                    },
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                );
              },
            ),

            Selector<HomeViewModel, Warehouse?>(
              selector: (_, vm) => vm.selectedWarehouse,
              builder: (context, selectedWarehouse, _) {
                if (selectedWarehouse == null) return const SizedBox.shrink();
                return CustomBottomSheet(
                  warehouse: selectedWarehouse,
                  isOpenNotifier: widget.isBottomSheetOpenNotifier,
                  onClose: () {
                    widget.isBottomSheetOpenNotifier.value = false;
                    context.read<HomeViewModel>().clearSelectedWarehouse();
                  },
                  onTap: () => _navigateToWarehouseManagement(selectedWarehouse),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBackPressed() async {
    if (widget.isBottomSheetOpenNotifier.value) {
      widget.isBottomSheetOpenNotifier.value = false;
      return;
    }

    // 여기에 기존 홈 화면 탭 이동 or 앱 종료 로직
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
              height: 60,
              width: double.infinity,
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
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
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

    if (result is Map<String, dynamic> && result['location'] is LatLng) {
      final LatLng location = result['location'];
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 16),
        ),
      );
    }
  }

  void _navigateToWarehouseManagement(Warehouse warehouse) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WarehouseManagement(warehouse: warehouse),
      ),
    );
  }
}
