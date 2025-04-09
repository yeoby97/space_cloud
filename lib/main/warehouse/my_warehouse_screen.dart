import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../data/warehouse.dart';
import '../warehouse/warehouse_management.dart';
import '../warehouse/warehouse_register_screen.dart';
import 'my_warehouse_view_model.dart';

class MyWarehouseScreen extends StatelessWidget {
  const MyWarehouseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyWarehouseViewModel(),
      child: const _MyWarehouseBody(),
    );
  }
}

class _MyWarehouseBody extends StatelessWidget {
  const _MyWarehouseBody();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MyWarehouseViewModel>();
    final formatter = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 창고 목록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '창고 등록',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const WarehouseRegisterScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Builder(
        builder: (_) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Center(child: Text(viewModel.error!));
          }

          final warehouses = viewModel.warehouses;

          if (warehouses.isEmpty) {
            return const Center(child: Text('등록된 창고가 없습니다.'));
          }

          return ListView.builder(
            itemCount: warehouses.length,
            itemBuilder: (context, index) {
              final warehouse = warehouses[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: warehouse.images.isNotEmpty
                      ? Image.network(
                    warehouse.images.first,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  )
                      : const Icon(Icons.home_work),
                  title: Text(warehouse.address),
                  subtitle: Text('₩${formatter.format(warehouse.price)} / ${warehouse.count}칸'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WarehouseManagement(warehouse: warehouse),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}