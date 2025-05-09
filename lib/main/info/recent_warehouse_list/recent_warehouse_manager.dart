import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/warehouse.dart';

class RecentWarehouseManager {
  static const _key = 'recent_warehouses';
  static const _limit = 10;

  static Future<void> addWarehouse(Warehouse warehouse) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];

    list.removeWhere((item) => jsonDecode(item)['id'] == warehouse.id);
    list.insert(0, jsonEncode(warehouse.toJson()));

    if (list.length > _limit) list.removeLast();

    await prefs.setStringList(_key, list);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await docRef.set({'recentWarehouses': list}, SetOptions(merge: true));
    }
  }

  static Future<List<Warehouse>> getLocalWarehouses() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map((e) => Warehouse.fromJson(jsonDecode(e))).toList();
  }

  // static메소드 - 별도의 인스턴스 없이 활용가능
  static Future<void> syncFromFirestore() async {
    // 현제 유저 가져옴
    final user = FirebaseAuth.instance.currentUser;
    // 유저가 없다면 리턴
    if (user == null) return;

    // 여기서부터 유저 존재

    // 유저의 문서를 가져옴
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    // recentWarehouses 필드 list에 담음, 없으면 빈 리스트
    final list = List<String>.from(doc.data()?['recentWarehouses'] ?? []);
    //
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, list);
  }

  static Future<void> clearLocalRecentWarehouses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_warehouses');

  }

}
