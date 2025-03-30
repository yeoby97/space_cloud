import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:space_cloud/main/home/search_screen.dart';

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
          _floatingButton(),
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

  Align _floatingButton() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
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
        zoom: 18.0,
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
        zoom: 17.0,
      ),
    ));
  }

  Future<void> _loadWarehouseMarkers() async {
    final snapshot = await FirebaseFirestore.instance.collection('warehouse').get();

    final markers = <String, Marker>{};

    for (var doc in snapshot.docs) {
      final data = doc.data();

      final lat = data['lat'];
      final lng = data['lng'];
      final address = data['address'] ?? '주소 없음';
      final marker = Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: address),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );

      markers[doc.id] = marker;
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
              height: 50,
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
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          '장소, 위치 검색',
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