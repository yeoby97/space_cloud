import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/warehouse.dart';
import '../home/bottom_sheet/favorite/favorite_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class HomeViewModel extends ChangeNotifier {
  final List<Marker> _markers = [];
  Warehouse? _selectedWarehouse;
  final Set<String> _favoriteWarehouseIds = {};
  final FavoriteService _favoriteService = FavoriteService();
  final Map<MarkerId, Warehouse> _markerWarehouseMap = {};

  List<Marker> get markers => _markers;
  Warehouse? get selectedWarehouse => _selectedWarehouse;
  Set<String> get favoriteWarehouseIds => _favoriteWarehouseIds;

  HomeViewModel() {
    _loadFavoriteWarehouses();
  }

  void loadWarehouseMarkers({required void Function(Warehouse) onTapWarehouse}) async {
    final snapshot = await FirebaseFirestore.instance.collection('warehouse').get();

    _markers.clear();
    for (var doc in snapshot.docs) {
      final warehouse = Warehouse.fromDoc(doc);

      if (warehouse.images.isNotEmpty && navigatorKey.currentContext != null) {
        precacheImage(NetworkImage(warehouse.images.first), navigatorKey.currentContext!);
      }

      final markerId = MarkerId(warehouse.id);
      final marker = Marker(
        markerId: markerId,
        position: LatLng(warehouse.lat, warehouse.lng),
        onTap: () {
          _selectedWarehouse = _markerWarehouseMap[markerId];
          notifyListeners();
          onTapWarehouse(_selectedWarehouse!);
        },
      );

      _markers.add(marker);
      _markerWarehouseMap[markerId] = warehouse;

    }

    notifyListeners();
  }

  void clearSelectedWarehouse() {
    _selectedWarehouse = null;
    notifyListeners();
  }

  void clearMarkers() {
    _markers.clear();
    notifyListeners();
  }

  Future<void> _loadFavoriteWarehouses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ids = await _favoriteService.getFavoriteWarehouseIdsOnce(user.uid);
    _favoriteWarehouseIds.clear();
    _favoriteWarehouseIds.addAll(ids);
    notifyListeners();
  }

  bool isFavorite(String warehouseId) {
    return _favoriteWarehouseIds.contains(warehouseId);
  }

  Future<void> toggleFavorite(Warehouse warehouse) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_favoriteWarehouseIds.contains(warehouse.id)) {
      _favoriteWarehouseIds.remove(warehouse.id);
      notifyListeners();
      await _favoriteService.removeFavorite(user.uid, warehouse.id);
    } else {
      _favoriteWarehouseIds.add(warehouse.id);
      notifyListeners();
      await _favoriteService.addFavorite(user.uid, warehouse);
    }
  }

  Warehouse? getWarehouseById(String id) {
    final markerId = MarkerId(id);
    return _markerWarehouseMap[markerId];
  }
}
