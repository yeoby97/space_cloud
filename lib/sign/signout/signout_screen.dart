import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../main/main_screen.dart';
import '../../main/home/home_view_model.dart';
import '../../main/home/my_location/my_location_view_model.dart';
import '../../data/user_view_model.dart';

void showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('로그아웃'),
      content: const Text('정말 로그아웃할까요?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context); // 먼저 다이얼로그 닫기
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider(create: (_) => HomeViewModel()),
                      ChangeNotifierProvider(create: (_) => MyLocationViewModel()),
                      ChangeNotifierProvider(create: (_) => UserViewModel()),
                    ],
                    child: const MainScreen(),
                  ),
                ),
                    (_) => false,
              );
            }
          },
          child: const Text('확인'),
        ),
      ],
    ),
  );
}
