import 'dart:async';
import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/warehouse.dart';

class MyWarehouseViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Warehouse> _warehouses = [];
  StreamSubscription? _subscription; // Stream<dynamic> 이므로 구체 타입 생략
  bool _isLoading = false;
  String? _error;

  List<Warehouse> get warehouses => _warehouses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> startListening() async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('로그인이 필요합니다.');
      return;
    }

    _setLoading(true);

    try {
      final rootSnapshot = await _firestore.collection('warehouse').get();
      final List<Stream<QuerySnapshot>> streams = [];

      for (final rootDoc in rootSnapshot.docs) {
        final stream = rootDoc.reference
            .collection('warehouses')
            .orderBy('createdAt', descending: true)
            .snapshots();

        streams.add(stream);
      }

      final mergedStream = StreamGroup.merge(streams);

      _subscription?.cancel();
      _subscription = mergedStream.listen((event) {
        final List<Warehouse> userWarehouses = [];

        if (event is QuerySnapshot) {
          for (final doc in event.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['ownerId'] == user.uid) {
              userWarehouses.add(Warehouse.fromDoc(doc));
            }
          }

          final Map<String, Warehouse> unique = {
            for (var w in _warehouses) w.id: w,
            for (var w in userWarehouses) w.id: w,
          };

          _warehouses = unique.values.toList()
            ..sort((a, b) =>
                (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

          notifyListeners();
        }
      });

      _setError(null);
    } catch (e) {
      _setError('에러 발생: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    stopListening();
    await startListening();
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _setError(String? message) {
    if (_error != message) {
      _error = message;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
