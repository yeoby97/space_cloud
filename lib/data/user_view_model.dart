import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/user.dart';
import '../main/info/recent_warehouse_list/recent_warehouse_manager.dart';

class UserViewModel extends ChangeNotifier {

  // 앱유저 선언
  AppUser? _appUser;
  AppUser? get appUser => _appUser;
  // 로딩중인지 확인용 변수
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 유저 정보 로드
  Future<void> loadUser() async {
    // 현제 로그인중인 유저 정보 받아옴
    final user = FirebaseAuth.instance.currentUser;
    // 로그인 중이지 않다면 리턴
    if (user == null) return;

    // 여기부터는 로그인중인 유저가 있다고 판단

    // 로딩값 true
    _isLoading = true;
    // 리스너에게 알림 - 로딩 시작
    notifyListeners();
    // 해당 유저 정보 받아옴
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    // 오류 없이 정보를 받아왔을때
    if (doc.exists) {
      // 앱유저에 정보 저장
      _appUser = AppUser.fromMap(doc.data()!);
      //
      await RecentWarehouseManager.syncFromFirestore();
      await RecentWarehouseManager.clearLocalRecentWarehouses();
      await RecentWarehouseManager.syncFromFirestore();
    }

    _isLoading = false;
    notifyListeners();
  }

  void updatePhoneNumber(String newNumber) {
    _appUser = _appUser?.copyWith(phoneNumber: newNumber);
    notifyListeners();
  }

  void updatePhotoURL(String newUrl) {
    _appUser = _appUser?.copyWith(photoURL: newUrl);
    notifyListeners();
  }
}
