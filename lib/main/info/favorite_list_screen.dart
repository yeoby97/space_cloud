import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/warehouse.dart';
import '../home/home_view_model.dart';
import '../home/bottom_sheet/favorite/favorite_button.dart';

class FavoriteListScreen extends StatelessWidget {
  const FavoriteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeVM = context.watch<HomeViewModel>();
    final markers = homeVM.markers;
    final favoriteIds = homeVM.favoriteWarehouseIds;

    final favoriteWarehouses = markers
        .where((marker) => favoriteIds.contains(marker.markerId.value))
        .map((marker) => homeVM.getWarehouseById(marker.markerId.value))
        .where((warehouse) => warehouse != null)
        .cast<Warehouse>()
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('찜한 창고')),
      body: ListView.builder(
        itemCount: favoriteWarehouses.length,
        itemBuilder: (context, index) {
          final warehouse = favoriteWarehouses[index];
          return ListTile(
            title: Text(warehouse.address),
            subtitle: Text(warehouse.detailAddress),
            trailing: FavoriteButton(warehouse: warehouse),
          );
        },
      ),
    );
  }
}
