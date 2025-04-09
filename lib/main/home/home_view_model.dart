import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/warehouse.dart';

class HomeViewModel extends ChangeNotifier {
  final List<Marker> _markers = [];
  Warehouse? _selectedWarehouse;

  List<Marker> get markers => _markers;
  Warehouse? get selectedWarehouse => _selectedWarehouse;

  void loadWarehouseMarkers({required void Function(Warehouse) onTapWarehouse}) async {
    final snapshot = await FirebaseFirestore.instance.collection('warehouse').get();

    _markers.clear();
    for (var doc in snapshot.docs) {
      final warehouse = Warehouse.fromDoc(doc);
      final marker = Marker(
        markerId: MarkerId(warehouse.id),
        position: LatLng(warehouse.lat, warehouse.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: warehouse.address),
        onTap: () {
          _selectedWarehouse = warehouse;
          notifyListeners();
          onTapWarehouse(warehouse);
        },
      );
      _markers.add(marker);
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
}
