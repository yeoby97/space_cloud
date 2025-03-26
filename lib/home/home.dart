import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../detail/detail_info.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final Map<String, Marker> _markers = {};     // 창고들 마커로 표기
  // 맵 생성시 작동 함수 - 창고 목록 가져와 마커로 표기
  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _markers.clear();
      _markers['대구'] = Marker(
          markerId: const MarkerId('대구'),
          position: const LatLng(35.873599, 128.631164),
          onTap: () {
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Expanded(
        child: GoogleMap(
          myLocationEnabled: true,
          onMapCreated: _onMapCreated,
          initialCameraPosition: const CameraPosition(
            target: LatLng(35.873599, 128.631164),
            zoom: 15,
          ),
          markers: _markers.values.toSet(),
        ),
      ),
    );
  }

}
