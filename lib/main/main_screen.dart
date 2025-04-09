import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import 'package:space_cloud/main/warehouse/my_warehouse_screen.dart';
import 'package:space_cloud/main/info/info_screen.dart';
import 'package:space_cloud/main/home/home_screen.dart';
import 'package:space_cloud/main/list/list_screen.dart';

import '../sign/signin/signin_screen.dart';
import 'home/my_location/my_location_view_model.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;
  final ValueNotifier<bool> _isBottomSheetOpen = ValueNotifier(false);
  User? user = FirebaseAuth.instance.currentUser;
  late final List<Widget> _bodies;

  @override
  void initState() {
    super.initState();

    _bodies = [
      HomeScreen(isBottomSheetOpenNotifier: _isBottomSheetOpen),
      const MyWarehouseScreen(),
      ListScreen(),
      const InfoScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyLocationViewModel(),
      child: WillPopScope(
        onWillPop: () async {
          if (_currentIndex != 0) {
            setState(() => _currentIndex = 0);
            return false;
          }

          if (_isBottomSheetOpen.value) {
            _isBottomSheetOpen.value = false;
            return false;
          }

          final now = DateTime.now();
          if (_lastBackPressed == null ||
              now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
            _lastBackPressed = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('뒤로 버튼을 한 번 더 누르면 종료됩니다.')),
            );
            return false;
          }

          return true;
        },
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
                child: const Icon(Icons.home),
                label: '홈',
                onTap: () => _setTab(0),
              ),
              SpeedDialChild(
                child: const Icon(Icons.warehouse),
                label: '내 창고',
                onTap: () => _setTab(1),
              ),
              SpeedDialChild(
                child: const Icon(Icons.calendar_month),
                label: '예약현황',
                onTap: () => _setTab(2),
              ),
              SpeedDialChild(
                child: const Icon(Icons.person),
                label: '내 정보',
                onTap: () => _setTab(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}