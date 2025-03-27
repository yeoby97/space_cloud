import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

import 'package:space_cloud/main/warehouse/warehouse_screen.dart';
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

  final List<Map<String, dynamic>> _navItems = const [    // NavigationBarItem 목록
    {'icon': Icons.home, 'label': '홈',},
    {'icon': Icons.warehouse, 'label': '내 창고',},
    {'icon': Icons.calendar_month, 'label': '예약현황',},
    {'icon': Icons.person, 'label': '내 정보',},
  ];
  final List<Widget> _bodies = const [
    HomeScreen(),
    WarehouseScreen(),
    ListScreen(),
    InfoScreen(),
  ];

  late Location _location;

  @override
  void initState() {
    super.initState();
    _location = Location();
    sendPermission();       // 권한 요청
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyLocationViewModel(),
      child: Scaffold(
        bottomNavigationBar: _BottomNavBar(
          navItems: _navItems,
          onTap: _onItemTapped,
          currentIndex: _currentIndex,
        ),
        body: _bodies[_currentIndex],
      ),
    );
  }

  // 권한 요청 함수
  Future<void> sendPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        // 위치 서비스가 비활성화된 경우 처리할 로직
        return;
      }
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
    }
    // 권한이 승인되었으면, 위치 서비스 활성화
    if (permissionGranted == PermissionStatus.granted) {
      // 위치 정보를 가져올 수 있도록 추가 로직을 작성할 수 있습니다.
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}

// NavigationBar
class _BottomNavBar extends StatelessWidget {
  final List<Map<String, dynamic>> navItems;
  final ValueChanged<int>? onTap;
  final int currentIndex;

  const _BottomNavBar({
    super.key,
    required this.navItems,
    required this.onTap,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: onTap,
      items: navItems
          .map((item) => BottomNavigationBarItem(
        icon: Icon(item['icon']),
        label: item['label'],
      ))
          .toList(),
    );
  }
}
