import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/user.dart';
import '../main/info/recent_warehouse_list/recent_warehouse_manager.dart';

class UserViewModel extends ChangeNotifier {
  AppUser? _appUser;
  AppUser? get appUser => _appUser;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      _appUser = AppUser.fromMap(doc.data()!);
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
