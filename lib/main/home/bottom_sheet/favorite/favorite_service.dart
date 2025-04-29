import 'package:cloud_firestore/cloud_firestore.dart';
import '/data/warehouse.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addFavorite(String userId, Warehouse warehouse) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(warehouse.id)
        .set({
      'address': warehouse.address,
      'detailAddress': warehouse.detailAddress,
      'price': warehouse.price,
      'images': warehouse.images,
    });
  }

  Future<void> removeFavorite(String userId, String warehouseId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(warehouseId)
        .delete();
  }

  Future<List<String>> getFavoriteWarehouseIdsOnce(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }
}
