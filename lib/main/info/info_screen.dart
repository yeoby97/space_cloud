import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:space_cloud/main/info/using_spaces_screen.dart';
import 'package:space_cloud/main/list/list_screen.dart';
import 'package:space_cloud/main/warehouse/my_warehouse_screen.dart';
import 'package:space_cloud/sign/signout/signout_screen.dart';

import '../../data/user.dart';
import '../../sign/signin/signin_screen.dart';
import '../home/home_screen.dart';
import '../main_screen.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  AppUser? appUser;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    if (!mounted) return;
    if (doc.exists) {
      setState(() {
        appUser = AppUser.fromMap(doc.data()!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTitle(),
            _buildProfileSection(),
            const SizedBox(height: 10),
            if (appUser != null) _buildPhoneSection(), // user != null일 땐 appUser도 체크
            const SizedBox(height: 10),
            _buildMenuSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          '마이페이지',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey.withAlpha(50),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.grey[300],
              child: appUser?.photoURL == null || appUser!.photoURL.isEmpty
                  ? const Icon(Icons.person, size: 40, color: Colors.grey,)
                  : ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  appUser!.photoURL,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.person),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: user == null
                  ? GestureDetector(
                onTap: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SignInScreen(),
                    ),
                  );
                  if (result == true) {
                    user = FirebaseAuth.instance.currentUser;
                    await _loadUserData();
                    if (mounted) setState(() {});
                  }
                },
                child: Row(
                  children: const [
                    Text(
                      '로그인 & 가입하기',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                    Icon(Icons.chevron_right, color: Colors.blue),
                  ],
                ),
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user!.displayName ?? '이름 없음'),
                  Text(user!.email ?? '이메일 없음'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.grey.withAlpha(50),
        ),
        child: Row(
          children: [
            const Icon(Icons.phone, size: 24, color: Colors.black54),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                formatPhoneNumber(appUser!.phoneNumber),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: 전화번호 수정
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('수정', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 1,
                side: BorderSide(color: Colors.grey.shade300),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Expanded(
      child: Column(
        children: [
          _buildFavorite(),
          _buildRecentlyView(),
          const Divider(
            indent: 20,
            endIndent: 20,
          ),
          const Spacer(),
          _buildSignOut(),
        ],
      ),
    );
  }

  Widget _buildFavorite() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () {
          print("찜한 창고 클릭됨");
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '찜한 창고',
                style: TextStyle(fontSize: 20),
              ),
              Icon(Icons.arrow_forward_ios_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentlyView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () {
          print("최근 본 창고 클릭됨");
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '최근 본 창고',
                style: TextStyle(fontSize: 20),
              ),
              Icon(Icons.arrow_forward_ios_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOut() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SignoutScreen()
            ),
          );
        },
        child: Text(
          '로그아웃',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  void _showProfileOptions(BuildContext context) {
    if (user == null) return;

    showDialog(   // 다이어로그 설정
      context: context, // context - 현재 화면 / 내가 있는 경로에 Dialog를 띄어줘야 하기 때문
      builder: (_) => AlertDialog(
        title: const Text("프로필 사진 변경"),
        content: Column(
          mainAxisSize: MainAxisSize.min, // column의 세로길이를 자식 위젯의 크기만큼만 지정 - 디폴트는 부모위젯의 크기
          children: [
            ListTile( //
              leading: const Icon(Icons.photo),
              title: const Text("갤러리에서 선택"),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndUploadImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("기본 이미지 사용"),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .update({'photoURL': user!.photoURL});
                setState(() {
                  appUser = appUser!.copyWith(photoURL: user!.photoURL);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    if (user == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    _showLoadingDialog(context);

    try {
      final fileName = '${user!.uid}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(fileName);

      await storageRef.putFile(imageFile);
      final downloadURL = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'photoURL': downloadURL});

      setState(() {
        appUser = appUser!.copyWith(photoURL: downloadURL);
      });
    } catch (e) {
      print("업로드 실패: $e");
    } finally {
      Navigator.pop(context);
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("업로드 중..."),
          ],
        ),
      ),
    );
  }

  String formatPhoneNumber(String phone) {
    if (phone.length == 11) {
      return '${phone.substring(0, 3)}-${phone.substring(3, 7)}-${phone.substring(7)}';
    } else if (phone.length == 10) {
      return '${phone.substring(0, 3)}-${phone.substring(3, 6)}-${phone.substring(6)}';
    }
    return phone;
  }

  void pushAfterClearingToHome(BuildContext context, Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainScreen(),
      ),
    );

    Future.delayed(Duration.zero, () {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => screen),
      );
    });
  }
}
