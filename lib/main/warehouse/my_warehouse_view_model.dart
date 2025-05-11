// TODO : 최적화 및 상태 최상단화
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

  Future<void> _loadWarehouses() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ 현재 로그인된 유저 없음');
      _isLoading = false;
      notifyListeners();
      return;
    }

    print('✅ 로그인 UID: ${user.uid}');

    try {
      final rootSnapshot = await _firestore.collection('warehouse').get();
      print('📦 최상위 warehouse 문서 수: ${rootSnapshot.docs.length}');
      final List<Warehouse> allWarehouses = [];

      for (final doc in rootSnapshot.docs) {
        print('📄 주소 문서 ID: ${doc.id}');

        final subSnapshot = await doc.reference.collection('warehouses').get();
        print('🔍 → warehouses 수: ${subSnapshot.docs.length}');

        for (final wDoc in subSnapshot.docs) {
          final data = wDoc.data();
          print('📑 문서 데이터: $data');
          final ownerId = data['ownerId'];
          if (ownerId == user.uid) {
            allWarehouses.add(Warehouse.fromDoc(wDoc));
          } else {
            print("⚠️ 다른 유저의 문서: ${wDoc.id} / ownerId: $ownerId");
          }
        }
      }

      _warehouses = allWarehouses;
      _error = null;
    } catch (e) {
      _error = '에러 발생: $e';
      print('❗예외: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
