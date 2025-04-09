import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/warehouse.dart';

class MyWarehouseViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Warehouse> _warehouses = [];
  bool _isLoading = true;
  String? _error;

  List<Warehouse> get warehouses => _warehouses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  MyWarehouseViewModel() {
    _loadWarehouses();
  }

  void _loadWarehouses() {
    final user = _auth.currentUser;
    if (user == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _firestore
        .collection('warehouse')
        .where('ownerId', isEqualTo: user.uid)
        .snapshots()
        .listen(
          (snapshot) {
        _warehouses = snapshot.docs.map((doc) => Warehouse.fromDoc(doc)).toList();
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = '에러 발생: $e';
        _isLoading = false;
        notifyListeners();
      },
    );
  }
}