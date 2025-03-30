import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:space_cloud/sign/signin/signin_screen.dart';
import 'firebase/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 파이어베이스 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignInScreen(),
    ),
  );
}
