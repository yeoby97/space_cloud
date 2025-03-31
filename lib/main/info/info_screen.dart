import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:space_cloud/main/info/usage_history_screen.dart';

import '../../data/user.dart';
class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {

  late User user;
  AppUser? appUser;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser!;
    _loadUserData(); // 비동기 로직은 따로 처리
  }

  Future<void> _loadUserData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      setState(() {
        appUser = AppUser.fromMap(doc.data()!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return appUser == null ?
      Scaffold(
        body: Center(
          child: CircularProgressIndicator(), // 또는 커스텀 로딩 화면
        ),
      )
     :
      Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Container(
                padding: EdgeInsets.all(10),
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey.withAlpha(50),
                ),
                child: Row(
                  spacing: 20,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15), // 둥근 사각형
                          child: Image.network(
                            appUser?.photoURL ?? '', // 혹시 null일 수도 있어서 방어적 코드
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 70,
                                height: 70,
                                color: Colors.grey,
                                child: Icon(Icons.person, size: 40),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              _showProfileOptions(context);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              padding: EdgeInsets.all(5),
                              child: Icon(Icons.edit, size: 16, color: Colors.black54),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${user.displayName}'),
                        Text('${user.email}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.grey.withAlpha(50),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone, size: 24, color: Colors.black54),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        formatPhoneNumber(appUser!.phoneNumber),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: 전화번호 수정 다이얼로그 등
                      },
                      icon: Icon(Icons.edit, size: 16),
                      label: Text('수정', style: TextStyle(fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Container(
                padding: EdgeInsets.all(10),
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey.withAlpha(50),
                ),
                child: Column(
                  spacing: 10,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      spacing: 30,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => UsageHistoryScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(12), // 터치 효과 둥글게
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history, size: 30),
                              SizedBox(height: 4),
                              Text('이용내역'),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => UsageHistoryScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(12), // 터치 효과 둥글게
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warehouse_outlined, size: 30),
                              SizedBox(height: 4),
                              Text('이용중'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showProfileOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("프로필 사진 변경"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo),
              title: Text("갤러리에서 선택"),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndUploadImage(); // 갤러리 선택 및 업로드
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text("기본 이미지 사용"),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({'photoURL': user.photoURL});
                setState(() {
                  appUser = appUser!.copyWith(photoURL: user.photoURL);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      // 로딩 다이얼로그 띄우기
      _showLoadingDialog(context);

      try {
        String fileName = '${user.uid}.jpg';
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child(fileName);

        // Firebase Storage 업로드
        await storageRef.putFile(imageFile);

        // 다운로드 URL 받기
        String downloadURL = await storageRef.getDownloadURL();

        // Firestore 업데이트
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'photoURL': downloadURL});

        // 앱 내 상태 업데이트
        setState(() {
          appUser = appUser!.copyWith(photoURL: downloadURL);
        });
      } catch (e) {
        print("업로드 실패: $e");
        // 실패 알림 토스트 등을 원하면 여기서 처리
      } finally {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
      }
    }
  }
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // 뒤로가기/밖 터치로 안 닫히게
      builder: (context) => const AlertDialog(
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
    return phone; // 혹시나 다른 형식이면 그대로 반환
  }
}
