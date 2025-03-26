import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:space_cloud/home/Info.dart';
import 'package:space_cloud/home/home.dart';
import 'package:space_cloud/home/reservation.dart';
import 'package:space_cloud/home/warehouse.dart';

class HomeScreen extends StatefulWidget {
  final User? user;
  const HomeScreen({
    required this.user,
    super.key,
  });
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _navItems = const [    // NavigationBarItem 목록
    {'icon': Icons.home, 'label': '홈',},
    {'icon': Icons.warehouse, 'label': '내 창고',},
    {'icon': Icons.calendar_month, 'label': '예약현황',},
    {'icon': Icons.person, 'label': '내 정보',},
  ];
  final List<Widget> _bodies = const [
    Home(),
    Warehouse(),
    Reservation(),
    Info(),
  ];

  @override
  void initState() {
    sendPermission();       // 권한 요청
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      bottomNavigationBar: _BottomNavBar(
        navItems: _navItems,
        onTap: _onItemTapped,
        currentIndex: _currentIndex,
      ),
      body: _bodies[_currentIndex]
    );
  }

  // 권한 요청 함수
  Future<void> sendPermission() async{

    Location location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if(!serviceEnabled) {
      serviceEnabled = await location.requestService();
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
    }
  }

  void _onItemTapped(index) {
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
  const _BottomNavBar({super.key, required this.navItems, required this.onTap,required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: onTap,
      items:  navItems.map((item) => BottomNavigationBarItem(
        icon: Icon(item['icon']),
        label: item['label'],
        ),
      ).
      toList(),
    );
  }
}
