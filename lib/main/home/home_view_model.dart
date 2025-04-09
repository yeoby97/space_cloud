import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/warehouse.dart';

class HomeViewModel extends ChangeNotifier {
  final List<Marker> _markers = [];
  List<Marker> get markers => _markers;

  Future<void> loadWarehouseMarkers({
    required Function(Warehouse warehouse) onTapWarehouse,
  }) async {
    final snapshot = await FirebaseFirestore.instance.collection('warehouse').get();

    final List<Marker> newMarkers = snapshot.docs.map((doc) {
      final warehouse = Warehouse.fromDoc(doc);
      return Marker(
        markerId: MarkerId(warehouse.id),
        position: LatLng(warehouse.lat, warehouse.lng),
        infoWindow: InfoWindow(title: warehouse.address),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        onTap: () => onTapWarehouse(warehouse),
      );
    }).toList();

    _markers
      ..clear()
      ..addAll(newMarkers);
    notifyListeners();
  }
}