import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../main/home/my_location/my_location_view_model.dart';
import '../../main/main_screen.dart';

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
            await FirebaseAuth.instance.signOut();
            final locationVM = context.read<MyLocationViewModel>();
            locationVM.reset();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainScreen()),
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
