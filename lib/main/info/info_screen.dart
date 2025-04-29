// TODO : 최적화 및 상태 최상단화

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:space_cloud/data/user.dart';
import 'package:space_cloud/main/info/phone_number_manager.dart';
import 'package:space_cloud/main/info/profile_image_manager.dart';
import 'package:space_cloud/sign/signout/signout_screen.dart';

import '../../sign/signin/signin_screen.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  AppUser? appUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!mounted) return;
    if (doc.exists) {
      setState(() => appUser = AppUser.fromMap(doc.data()!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTitle(),
            _buildProfileSection(user),
            if (user != null && appUser != null) _buildPhoneSection(user),
            const SizedBox(height: 10),
            _buildMenuSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() => const Padding(
    padding: EdgeInsets.fromLTRB(20, 20, 0, 0),
    child: Align(
      alignment: Alignment.topLeft,
      child: Text('마이페이지', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
    ),
  );

  Widget _buildProfileSection(User? user) {
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
            GestureDetector(
              onTap: () {
                if (user != null && appUser != null) {
                  ProfileImageManager.show(
                    context,
                    user,
                        (newUrl) {
                      setState(() {
                        appUser = appUser!.copyWith(photoURL: newUrl);
                      });
                    },
                  );
                }
              },
              child: _buildAvatar(),
            ),
            const SizedBox(width: 20),
            Expanded(child: _buildUserInfo(user)),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final image = appUser?.photoURL;
    return CircleAvatar(
      radius: 35,
      backgroundColor: Colors.grey[300],
      child: image == null || image.isEmpty
          ? const Icon(Icons.person, size: 40, color: Colors.grey)
          : ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(
          image,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.person),
        ),
      ),
    );
  }

  Widget _buildUserInfo(User? user) {
    if (user == null) {
      return GestureDetector(
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SignInScreen()),
          );
          if (result == true) {
            await _loadUserData();
            if (mounted) setState(() {});
          }
        },
        child: const Row(
          children: [
            Text('로그인 & 가입하기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
            Icon(Icons.chevron_right, color: Colors.blue),
          ],
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.displayName ?? '이름 없음'),
          Text(user.email ?? '이메일 없음'),
        ],
      );
    }
  }

  Widget _buildPhoneSection(User user) {
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
                PhoneNumberManager.formatPhoneNumber(appUser!.phoneNumber),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                PhoneNumberManager.showPhoneNumberEditDialog(
                  context,
                  appUser!.phoneNumber,
                      (updatedPhone) => setState(() => appUser = appUser!.copyWith(phoneNumber: updatedPhone)),
                );
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('수정', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          _buildMenuItem('찜한 창고'),
          _buildMenuItem('최근 본 창고'),
          const Divider(indent: 20, endIndent: 20),
          const Spacer(),
          _buildSignOut(FirebaseAuth.instance.currentUser),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () => debugPrint('$title 클릭됨'),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(title, style: const TextStyle(fontSize: 20)), const Icon(Icons.arrow_forward_ios_rounded)],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOut(User? user) {
    if (user == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () => showLogoutDialog(context),
        child: const Text('로그아웃', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
