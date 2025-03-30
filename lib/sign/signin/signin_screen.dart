import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../main/main_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  User? _user;

  @override
  Widget build(BuildContext context) {
    // 로그인된 경우 바로 HomeScreen으로 이동
    return _user == null
        ? Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: _signInWithGoogle,
              child: const Text('Google 로그인'),
            ),
          ),
        )
        : MainScreen(user: _user);
  }

  Future<void> _signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // 사용자가 취소

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      setState(() {
        _user = userCredential.user;
      });
    } catch (e) {
      debugPrint("로그인 실패: $e");
    }
  }
}
