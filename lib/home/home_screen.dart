import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(_user?.photoURL ?? ''), // null 처리를 해줌
              radius: 40,
            ),
            const SizedBox(height: 10),
            Text('이름: ${_user?.displayName ?? '알 수 없음'}'), // null 처리
            Text('이메일: ${_user?.email ?? '알 수 없음'}'), // null 처리
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 로그아웃 처리
              },
              child: const Text('로그아웃'),
            )
          ],
        ),
      ),
    );
  }
}