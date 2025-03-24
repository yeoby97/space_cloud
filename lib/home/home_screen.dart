import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class HomeScreen extends StatelessWidget {
  final User? _user; // 생성자로 user를 받아옴

  // 생성자에서 User 객체를 받아옴
  const HomeScreen({
    required User? user,
    super.key,
  }) : _user = user;

  @override
  Widget build(BuildContext context) {
    // _user가 null이 아니면 사용자 정보 출력
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            NaverMap(),
          ],
        ),
      ),
    );
  }
}