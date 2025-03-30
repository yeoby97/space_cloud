import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:space_cloud/main/home/search_screen.dart';

import '../../data/warehouse.dart';
import '../warehouse/warehouse_detail.dart';
import 'my_location_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Marker> _markers = []; // 창고들 마커로 표기
  Warehouse? _selectedWarehouse; // 선택된 창고 정보
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    _loadWarehouseMarkers(); // 마커 불러오기
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _googleMap(),
          _SearchBox(onTap: _onTap,),
          SafeArea(child: _floatingButton()),
          if (_selectedWarehouse != null) _SelectedWarehouseCard(selectedWarehouse: _selectedWarehouse!),
        ]
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

        return showGoogleMap(currentPosition);
      },
    );
  }

  GoogleMap showGoogleMap(Position currentPosition) {
    return GoogleMap(
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      initialCameraPosition: CameraPosition(
        target: LatLng(currentPosition.latitude, currentPosition.longitude),
        zoom: 16,
      ),
      onMapCreated: (controller) {
        _mapController = controller; // GoogleMapController 초기화
      },
      markers: Set<Marker>.from(_markers),
    );
  }

  Align _floatingButton() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FloatingActionButton(
          shape: CircleBorder(),
          foregroundColor: Colors.black.withAlpha(150),
          backgroundColor: Colors.white,
          onPressed: () {
            _goToCurrentLocation();
          },
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

  void _onTap() async{
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return SearchScreen();
        },
      ),
    );
    _mapController.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        bearing: 0,
        target: result["location"],
        zoom: 16.0,
      ),
    ));
  }

  Future<void> _loadWarehouseMarkers() async {
    final snapshot = await FirebaseFirestore.instance.collection('warehouse').get();

    final markers = <Marker>[];

    for (var doc in snapshot.docs) {
      final warehouse = Warehouse.fromDoc(doc);

      final marker = Marker(
        markerId: MarkerId(warehouse.id),
        position: LatLng(warehouse.lat, warehouse.lng),
        infoWindow: InfoWindow(title: warehouse.address),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        onTap: () {
          setState(() {
            _selectedWarehouse = warehouse; // 선택된 창고 정보 저장
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
  const _SearchBox({super.key,required this.onTap});

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
              width: 500,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2), // 그림자 색상
                    blurRadius: 10,   // 흐림 정도
                    spreadRadius: 2,  // 그림자 확산 정도
                    offset: Offset(3, 3), // X, Y 방향 위치 조정
                  ),
                ],
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.map),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          '장소나 위치를 검색하세요.',
                          style: TextStyle(
                            color: Colors.black.withAlpha(100),
                          ),
                        ),
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

class _SelectedWarehouseCard extends StatefulWidget {
  final selectedWarehouse;
  const _SelectedWarehouseCard({super.key,required this.selectedWarehouse,});

  @override
  State<_SelectedWarehouseCard> createState() => _SelectedWarehouseCardState();
}


class _SelectedWarehouseCardState extends State<_SelectedWarehouseCard>
  with SingleTickerProviderStateMixin{
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0), // 아래에서 시작
      end: Offset.zero,              // 현재 위치로 이동
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward(); // 애니메이션 시작
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToDetailPage() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, animation, __) => WarehouseDetail(warehouse: widget.selectedWarehouse!),
        transitionsBuilder: (_, animation, __, child) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0, 1), // 아래에서 시작
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SlideTransition(
        position: _offsetAnimation,
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.primaryDelta! < -15) {
              // 위로 빠르게 드래그하면 페이지 이동
              _navigateToDetailPage();
            }
          },
          child: Container(
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
                bottom: Radius.circular(0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, -4), // 위쪽 그림자
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // 🔥 이미지
                  if (widget.selectedWarehouse.images.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        widget.selectedWarehouse.images.first,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 10),

                  // 🔥 정보들
                  Text(widget.selectedWarehouse.address, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(widget.selectedWarehouse.detailAddress),
                  const SizedBox(height: 6),
                  Text('가격: ${widget.selectedWarehouse.price}원'),
                  Text('보관 공간: ${widget.selectedWarehouse.count}칸'),
                  const SizedBox(height: 6),
                  Text('등록일: ${widget.selectedWarehouse.createdAt.toLocal().toString().split(' ').first}'),

                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {

                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
