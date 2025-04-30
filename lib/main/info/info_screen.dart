// TODO : 최적화 및 상태 최상단화

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:space_cloud/main/info/phone_number_manager.dart';
import 'package:space_cloud/main/info/profile_image_manager.dart';
import 'package:space_cloud/main/info/recent_warehouse_list/recent_list_screen.dart';
import 'package:space_cloud/sign/signout/signout_screen.dart';

import '../../data/user.dart';
import '../../data/user_view_model.dart';
import '../../sign/signin/signin_screen.dart';
import '../home/home_view_model.dart';
import 'favorite_list_screen.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userVM = context.watch<UserViewModel>();
    final appUser = userVM.appUser;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTitle(),
            _buildProfileSection(context, user, appUser, userVM),
            _buildPhoneSection(context, user, appUser, userVM),
            const SizedBox(height: 10),
            _buildMenuSection(context),
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

  Widget _buildProfileSection(BuildContext context, User? user, AppUser? appUser, UserViewModel userVM) {
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
                        (newUrl) => userVM.updatePhotoURL(newUrl),
                  );
                }
              },
              child: _buildAvatar(appUser),
            ),
            const SizedBox(width: 20),
            Expanded(child: _buildUserInfo(context, user)),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(AppUser? appUser) {
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

  Widget _buildUserInfo(BuildContext context, User? user) {
    if (user == null) {
      return GestureDetector(
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SignInScreen()),
          );
          if (result == true) {
            if (context.mounted) {
              context.read<UserViewModel>().loadUser();
            }
          }
        },
        child: const Row(
          children: [
            Text('로그인 & 가입하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
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

  Widget _buildPhoneSection(BuildContext context, User? user, AppUser? appUser, UserViewModel userVM) {
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
              child: Container(
                alignment: Alignment.centerLeft,
                constraints: const BoxConstraints(minHeight: 50),
                child: Text(
                  (user == null || appUser == null)
                      ? '로그인 후 이용해주세요.'
                      : PhoneNumberManager.formatPhoneNumber(appUser.phoneNumber),
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            const SizedBox(width: 10),
            if (user != null && appUser != null)
              ElevatedButton.icon(
                onPressed: () {
                  PhoneNumberManager.showPhoneNumberEditDialog(
                    context,
                    appUser.phoneNumber,
                        (updatedPhone) => userVM.updatePhoneNumber(updatedPhone),
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          _buildFavoriteList(context),
          _buildRecentList(context),
          const Divider(indent: 20, endIndent: 20),
          const Spacer(),
          _buildSignOut(context),
        ],
      ),
    );
  }

  Widget _buildFavoriteList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: context.read<HomeViewModel>(),
                child: const FavoriteListScreen(),
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('찜한 창고', style: const TextStyle(fontSize: 20)),
              const Icon(Icons.arrow_forward_ios_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: context.read<HomeViewModel>(),
                child: const RecentListScreen(),
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('최근 본 창고', style: const TextStyle(fontSize: 20)),
              const Icon(Icons.arrow_forward_ios_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOut(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
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
