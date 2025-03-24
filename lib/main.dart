import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:space_cloud/sign/signin/signin_screen.dart';
import 'firebase/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 파이어베이스 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 네이버 지도 초기화
  await NaverMapSdk.instance.initialize(
      clientId: '2t4gtv24kh',
      onAuthFailed: (error) {
        print('Auth failed: $error');
      });

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignInScreen(),
    ),
  );
}

