import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../data/user.dart';
import '../../main/main_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  User? _user = FirebaseAuth.instance.currentUser;

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
        : MainScreen();
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

      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final newUser = AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email,
          displayName: firebaseUser.displayName,
          photoURL: firebaseUser.photoURL,
          phoneNumber: firebaseUser.phoneNumber ?? '01012345678', // null 방지
        );
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid);

        // Firestore에 문서 존재 여부 확인
        final docSnapshot = await docRef.get();

        if (!docSnapshot.exists) {
          await docRef.set(newUser.toMap());
          debugPrint('Firestore에 사용자 정보 저장 완료');
        }
        setState(() {
          _user = userCredential.user;
        });
      }
    } catch (e) {
      debugPrint("로그인 실패: $e");
    }
  }
}
