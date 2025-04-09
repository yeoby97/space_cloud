import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileImageManager {
  final BuildContext context;
  final User user;
  final void Function(String photoUrl) onPhotoUpdated;

  ProfileImageManager({
    required this.context,
    required this.user,
    required this.onPhotoUpdated,
  });

  static void show(
      BuildContext context,
      User user,
      void Function(String photoUrl) onPhotoUpdated,
      ) {
    final manager = ProfileImageManager(
      context: context,
      user: user,
      onPhotoUpdated: onPhotoUpdated,
    );
    manager._showOptionsDialog();
  }

  void _showOptionsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("프로필 사진 변경"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
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
                await _setDefaultImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setDefaultImage() async {
    const defaultImageUrl = '';

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'photoURL': defaultImageUrl});
      onPhotoUpdated(defaultImageUrl);
    } catch (e) {
      _showErrorDialog("기본 이미지 설정에 실패했습니다.");
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final imageFile = File(pickedFile.path);
    _showLoadingDialog();

    try {
      final fileName = '${user.uid}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(fileName);

      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'photoURL': downloadUrl});

      onPhotoUpdated(downloadUrl);
    } catch (e) {
      _showErrorDialog("이미지 업로드에 실패했습니다.");
    } finally {
      if (Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  void _showLoadingDialog() {
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("오류"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }
}
