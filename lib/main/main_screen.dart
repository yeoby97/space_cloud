import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import 'package:space_cloud/main/warehouse/my_warehouse_screen.dart';
import 'package:space_cloud/main/info/info_screen.dart';
import 'package:space_cloud/main/home/home_screen.dart';
import 'package:space_cloud/main/list/list_screen.dart';

import 'home/my_location_view_model.dart';

class MainScreen extends StatefulWidget {
  final User? user;
  const MainScreen({
    required this.user,
    super.key,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late Location _location;

  final List<Widget> _bodies = const [
    HomeScreen(),
    MyWarehouseScreen(),
    ListScreen(),
    InfoScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyLocationViewModel(),
      child: Scaffold(
        body: _bodies[_currentIndex],
        floatingActionButton: SpeedDial(
          animatedIcon: AnimatedIcons.menu_close,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black.withAlpha(150),
          overlayOpacity: 0.3,
          spacing: 10,
          spaceBetweenChildren: 10,
          children: [
            SpeedDialChild(
              child: Icon(Icons.home),
              label: '홈',
              onTap: () => _setTab(0),
            ),
            SpeedDialChild(
              child: Icon(Icons.warehouse),
              label: '내 창고',
              onTap: () => _setTab(1),
            ),
            SpeedDialChild(
              child: Icon(Icons.calendar_month),
              label: '예약현황',
              onTap: () => _setTab(2),
            ),
            SpeedDialChild(
              child: Icon(Icons.person),
              label: '내 정보',
              onTap: () => _setTab(3),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _location = Location();
    sendPermission();
  }

  void _setTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> sendPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
    }
  }
}
