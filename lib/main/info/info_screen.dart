import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:space_cloud/main/info/using_spaces_screen.dart';

import '../../data/user.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final User user = FirebaseAuth.instance.currentUser!; // 파이어베이스 로그인 확인
  AppUser? appUser; // 유저 클래스 - 커스텀 유저 정보

  @override
  void initState() {  // 초기화 시에 유저데이터부터 가져옴
    super.initState();
    _loadUserData();  // 데이터 가져오기
  }

  Future<void> _loadUserData() async {
    // Firestore의 users collection 에서 user.uid이름을 가진 document 불러옴
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) { // 해당 문서가 존재하면
      setState(() {   // 화면 초기화
        appUser = AppUser.fromMap(doc.data()!); // 엡 유저는 doc.data를 AppUser로 변환해주는 factory 생성자
      });
    }
  }

  @override
  Widget build(BuildContext context) {  // 현제 페이지의 가장 상위 위젯 - 해당 위젯에 모든 화면 요소 담겨있음
    return appUser == null  // 유저가 null이라면 유저 정보를 불러오는 중이기 떄문에 로딩화면
        ? const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    )
        : Scaffold(   // 유저 데이터를 불러왔다면
      body: SafeArea( // 시스템바 침범 x
        child: Column(
          children: [
            _buildProfileSection(),   // 프로필 섹션 - 프로필, 이름, 이메일
            const SizedBox(height: 10),
            _buildPhoneSection(),
            const SizedBox(height: 10),
            _buildMenuSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {   // 프로필 섹션 - 프로필, 이름, 이메일
    return Padding(   // 패딩
      padding: const EdgeInsets.all(20),
      child: Container(   // 박스 위젯
        padding: const EdgeInsets.all(10),
        width: double.infinity,   // 너비 폰 화면 꽉차게
        height: 100,    // 높이
        decoration: BoxDecoration(   // 위젯 decoration
          borderRadius: BorderRadius.circular(20),  // border 20만큼 원형으로
          color: Colors.grey.withAlpha(50), // 50투명도 가진 grey
        ),
        child: Row(   // 프로필   이름,이메일
          children: [
            Stack(    // 여러 위젯을 겹칠 수 있도록 하는 위젯
              children: [
                ClipRRect(    // 사각형 위젯에 원형테두리를 주는 위젯
                  borderRadius: BorderRadius.circular(15),  // 15만큼 원형
                  child: Image.network(   // Uri로 이미지 띄어주는 위젯
                    appUser?.photoURL ?? '',
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover, // 이미지가 비율을 유지하며 위젯을 완전히 덮음 - 사진 일부 잘릴 수 있음
                    errorBuilder: (context, error, stackTrace) {  // 에러시 반환해줄 위젯
                      return Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey,
                        child: const Icon(Icons.person, size: 40),
                      );
                    },
                  ),
                ),
                Positioned(  // 위젯을 특정 위치에 배치하는 위젯 / 부모 내부에서
                  bottom: 0,  // 바닥
                  right: 0,   // 오른쪾
                  child: GestureDetector(   // 하위 위젯에 터치 등 event를 부여해주는 위젯
                    onTap: () => _showProfileOptions(context), // 클릭시 프로필 옵션 위젯이 뜨게 해준다.
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(5),
                      child: const Icon(Icons.edit, size: 16, color: Colors.black54),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.displayName ?? '이름 없음'),
                Text(user.email ?? '이메일 없음'),
              ],
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
                // TODO: 전화번호 수정 기능
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('수정', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey.withAlpha(50),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UsingSpacesScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
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
    );
  }

  void _showProfileOptions(BuildContext context) {
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

    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    _showLoadingDialog(context);

    try {
      final fileName = '${user.uid}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(fileName);

      await storageRef.putFile(imageFile);
      final downloadURL = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
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
}
