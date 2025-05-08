import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import 'package:space_cloud/main/warehouse/my_warehouse_screen.dart';
import 'package:space_cloud/main/info/info_screen.dart';
import 'package:space_cloud/main/home/home_screen.dart';
import 'package:space_cloud/main/list/list_screen.dart';
import 'package:space_cloud/main/warehouse/my_warehouse_view_model.dart';
import 'package:space_cloud/sign/signin/signin_screen.dart';

import 'home/home_view_model.dart';
import 'home/my_location/my_location_view_model.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;
  final ValueNotifier<bool> _isBottomSheetOpen = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => MyLocationViewModel()),
      ],
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _handleBackPressed();
        },
        child: Scaffold(
          body: _buildBody(),
          floatingActionButton: _buildFloatingButton(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return HomeScreen(isBottomSheetOpenNotifier: _isBottomSheetOpen);
      case 1:
        return ChangeNotifierProvider(
          create: (_) => MyWarehouseViewModel(),
          child: const MyWarehouseScreen(),
        );
      case 2:
        return const ListScreen();
      case 3:
        return const InfoScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFloatingButton() {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black.withAlpha(150),
      overlayOpacity: 0.3,
      spacing: 10,
      spaceBetweenChildren: 10,
      children: [
        _buildDial(icon: Icons.home, label: '홈', tab: 0),
        _buildDial(icon: Icons.warehouse, label: '내 창고', tab: 1),
        _buildDial(icon: Icons.calendar_month, label: '예약현황', tab: 2),
        _buildDial(icon: Icons.person, label: '내 정보', tab: 3),
      ],
    );
  }

  SpeedDialChild _buildDial({required IconData icon, required String label, required int tab}) {
    return SpeedDialChild(
      child: Icon(icon),
      label: label,
      onTap: () => _onTabSelected(tab),
    );
  }

  Future<void> _onTabSelected(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (index == 2 && user == null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
      if (result == null) return;
    }
    if (mounted) setState(() => _currentIndex = index);
  }

  void _handleBackPressed() {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }
    if (_isBottomSheetOpen.value) {
      _isBottomSheetOpen.value = false;
      return;
    }

    final now = DateTime.now();
    if (_lastBackPressed == null || now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('뒤로 버튼을 한 번 더 누르면 종료됩니다.')),
        );
      }
    } else {
      if (Platform.isAndroid) {
        SystemNavigator.pop();
      } else {
        exit(0);
      }
    }
  }
}
