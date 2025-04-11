import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
