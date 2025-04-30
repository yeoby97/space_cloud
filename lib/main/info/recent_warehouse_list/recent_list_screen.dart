import 'package:flutter/material.dart';
import 'package:space_cloud/data/warehouse.dart';
import 'package:space_cloud/main/info/recent_warehouse_list/recent_warehouse_manager.dart';

class RecentListScreen extends StatefulWidget {
  const RecentListScreen({super.key});

  @override
  State<RecentListScreen> createState() => _RecentListScreenState();
}

class _RecentListScreenState extends State<RecentListScreen> {
  List<Warehouse> _warehouses = [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final list = await RecentWarehouseManager.getLocalWarehouses();
    setState(() => _warehouses = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('최근 본 창고')),
      body: _warehouses.isEmpty
          ? const Center(child: Text('최근 본 창고가 없습니다.'))
          : ListView.builder(
        itemCount: _warehouses.length,
        itemBuilder: (context, index) {
          final warehouse = _warehouses[index];
          return ListTile(
            title: Text(warehouse.address),
            subtitle: Text(warehouse.detailAddress),
          );
        },
      ),
    );
  }
}
