// TODO : 최적화 및 상태 최상단화

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class WarehouseList extends StatelessWidget {
  final List<Map<String, dynamic>> warehouses;
  final bool loading;

  const WarehouseList({
    super.key,
    required this.warehouses,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (warehouses.isEmpty) {
      return const SizedBox();
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📦 10km 이내 최근 창고",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: warehouses.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final warehouse = warehouses[index];
                final distanceKm = (warehouse['distance'] / 1000).toStringAsFixed(2);
                return ListTile(
                  leading: const Icon(Icons.warehouse),
                  title: Text(warehouse['name']),
                  subtitle: Text("$distanceKm km 거리"),
                  onTap: () {
                    Navigator.of(context).pop({
                      'location': warehouse['latLng'] as LatLng,
                      'address': warehouse['name'],
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
