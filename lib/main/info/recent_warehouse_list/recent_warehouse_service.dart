import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/warehouse.dart';

class RecentWarehouseService {
  static const _prefsKey = 'recent_warehouses';
  static const _maxLength = 10;

  Future<List<Warehouse>> loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_prefsKey) ?? [];
    return jsonList.map((e) => Warehouse.fromJson(json.decode(e))).toList();
  }

  Future<void> addWarehouse(Warehouse warehouse) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_prefsKey) ?? [];

    jsonList.removeWhere((e) => Warehouse.fromJson(json.decode(e)).id == warehouse.id);
    jsonList.insert(0, json.encode(warehouse.toJson()));

    if (jsonList.length > _maxLength) {
      jsonList.removeLast();
    }

    await prefs.setStringList(_prefsKey, jsonList);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _syncToFirestore(user.uid, jsonList);
    }
  }

  Future<void> _syncToFirestore(String uid, List<String> jsonList) async {
    final firestore = FirebaseFirestore.instance;
    final docRef = firestore.collection('recent_warehouses').doc(uid);
    await docRef.set({'list': jsonList});
  }

  Future<void> syncFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('recent_warehouses').doc(user.uid);
    final doc = await docRef.get();
    if (doc.data()?['list'] is! List) return;

    final jsonList = List<String>.from(doc.data()!['list']);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, jsonList);
  }

  Future<void> clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
