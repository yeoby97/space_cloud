import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/warehouse.dart';
import '../home/bottom_sheet/favorite/favorite_service.dart';
import '../info/recent_warehouse_list/recent_warehouse_manager.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class HomeViewModel extends ChangeNotifier {
  final List<Marker> _markers = [];
  final Map<MarkerId, Warehouse> _markerWarehouseMap = {};
  final Set<String> _favoriteWarehouseIds = {};
  final FavoriteService _favoriteService = FavoriteService();

  Warehouse? _selectedWarehouse;
  StreamSubscription<QuerySnapshot>? _snapshotSub;
  bool _isListening = false;

  void Function(Warehouse)? _onTapWarehouseCallback;

  List<Marker> get markers => _markers;
  Warehouse? get selectedWarehouse => _selectedWarehouse;
  Set<String> get favoriteWarehouseIds => _favoriteWarehouseIds;

  HomeViewModel() {
    _loadFavoriteWarehouses();
  }

  void updateOnTapCallback(void Function(Warehouse) callback) {
    _onTapWarehouseCallback = callback;
  }

  void startListeningToWarehouses() {
    if (_isListening) return;
    _isListening = true;

    _snapshotSub = FirebaseFirestore.instance
        .collectionGroup('warehouses')
        .snapshots()
        .listen((snapshot) {
      _markers.clear();
      _markerWarehouseMap.clear();

      for (final doc in snapshot.docs) {
        final warehouse = Warehouse.fromDoc(doc);

        if (warehouse.images.isNotEmpty && navigatorKey.currentContext != null) {
          precacheImage(NetworkImage(warehouse.images.first), navigatorKey.currentContext!);
        }

        final markerId = MarkerId(warehouse.id);
        final marker = Marker(
          markerId: markerId,
          position: LatLng(warehouse.lat, warehouse.lng),
          onTap: () {
            _selectedWarehouse = warehouse;
            notifyListeners();
            RecentWarehouseManager.addWarehouse(warehouse);
            _onTapWarehouseCallback?.call(warehouse);
          },
        );

        _markers.add(marker);
        _markerWarehouseMap[markerId] = warehouse;
      }

      notifyListeners();
    });
  }

  void clearSelectedWarehouse() {
    if (_selectedWarehouse != null) {
      _selectedWarehouse = null;
      notifyListeners();
    }
  }

  Future<void> _loadFavoriteWarehouses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ids = await _favoriteService.getFavoriteWarehouseIdsOnce(user.uid);
    _favoriteWarehouseIds
      ..clear()
      ..addAll(ids);

    notifyListeners();
  }

  bool isFavorite(String warehouseId) => _favoriteWarehouseIds.contains(warehouseId);

  Future<void> toggleFavorite(Warehouse warehouse) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final id = warehouse.id;
    final wasFavorite = _favoriteWarehouseIds.contains(id);

    if (wasFavorite) {
      _favoriteWarehouseIds.remove(id);
      notifyListeners();
      await _favoriteService.removeFavorite(user.uid, id);
    } else {
      _favoriteWarehouseIds.add(id);
      notifyListeners();
      await _favoriteService.addFavorite(user.uid, warehouse);
    }
  }

  Warehouse? getWarehouseById(String id) {
    return _markerWarehouseMap[MarkerId(id)];
  }

  @override
  void dispose() {
    _snapshotSub?.cancel();
    _isListening = false;
    super.dispose();
  }
}
