import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:space_cloud/detail/detail_info.dart';
class HomeScreen extends StatefulWidget {
  final User? _user;
  const HomeScreen({
    required User? user,
    super.key,
  }) : _user = user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, Marker> _markers = {};
  late GoogleMapController _mapController;

  @override
  Widget build(BuildContext context) {
    // _user가 null이 아니면 사용자 정보 출력
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index){},
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
        ],
      ),
      body: Stack(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: LatLng(35.873599, 128.631164),
                zoom: 15,
              ),
              markers: _markers.values.toSet(),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: FloatingActionButton(
              onPressed: _goToMyLocation,
              child: const Icon(Icons.my_location),
            ),
          )
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller){
    _mapController = controller;
    _goToMyLocation();

    setState(() {
      _markers.clear();
      _markers['대구'] = Marker(
        markerId: const MarkerId('대구'),
        position: const LatLng(35.873599, 128.631164),
        onTap: (){
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DetailInfo(),
            ),
          );
        }
      );
    });
  }

  Future<void> _goToMyLocation() async {
    Location location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if(!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();

    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if( permissionGranted != PermissionStatus.granted) return;
    }
    
    LocationData myLocation = await location.getLocation();
    
    _mapController.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(myLocation.latitude!, myLocation.longitude!,),
      ),
    );

    setState(() {
      _markers['내 위치'] = Marker(
        markerId: MarkerId('myLocation'),
        position: LatLng(myLocation.latitude!, myLocation.longitude!),
        infoWindow: InfoWindow(title: '내 위치'),
      );
    });
  }
}