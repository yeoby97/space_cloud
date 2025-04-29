// TODO : 최적화 및 상태 최상단화

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'favorite_service.dart';
import '/data/warehouse.dart';

class FavoriteViewModel extends ChangeNotifier {
  final FavoriteService _favoriteService;
  final Set<String> _favoriteWarehouseIds = {};

  FavoriteViewModel({required FavoriteService favoriteService})
      : _favoriteService = favoriteService {
    _loadFavorites();
  }

  Set<String> get favoriteWarehouseIds => _favoriteWarehouseIds;

  Future<void> _loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ids = await _favoriteService.getFavoriteWarehouseIdsOnce(user.uid);
    _favoriteWarehouseIds.clear();
    _favoriteWarehouseIds.addAll(ids);
    notifyListeners();
  }

  Future<void> toggleFavorite(Warehouse warehouse) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final warehouseId = warehouse.id;

    if (_favoriteWarehouseIds.contains(warehouseId)) {
      _favoriteWarehouseIds.remove(warehouseId);
      notifyListeners();
      await _favoriteService.removeFavorite(user.uid, warehouseId);
    } else {
      _favoriteWarehouseIds.add(warehouseId);
      notifyListeners();
      await _favoriteService.addFavorite(user.uid, warehouse);
    }
  }

  bool isFavorite(String warehouseId) {
    return _favoriteWarehouseIds.contains(warehouseId);
  }
}
