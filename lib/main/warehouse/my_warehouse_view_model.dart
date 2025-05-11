import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/warehouse.dart';

class MyWarehouseViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Warehouse> _warehouses = [];
  bool _isLoading = false;
  String? _error;
  bool _hasLoaded = false;

  List<Warehouse> get warehouses => _warehouses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadOnce() async {
    if (_hasLoaded) return;
    _hasLoaded = true;
    await _loadWarehouses();
  }

  Future<void> refresh() async {
    _hasLoaded = false;
    await _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    _setLoading(true);

    final user = _auth.currentUser;
    if (user == null) {
      _setError('로그인이 필요합니다.');
      return;
    }

    try {
      final rootSnapshot = await _firestore.collection('warehouse').get();
      final List<Warehouse> allWarehouses = [];

      for (final doc in rootSnapshot.docs) {
        final subSnapshot = await doc.reference.collection('warehouses').get();
        for (final wDoc in subSnapshot.docs) {
          final data = wDoc.data();
          if (data['ownerId'] == user.uid) {
            allWarehouses.add(Warehouse.fromDoc(wDoc));
          }
        }
      }

      _warehouses = allWarehouses;
      _setError(null);
    } catch (e) {
      _setError('에러 발생: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }
}
