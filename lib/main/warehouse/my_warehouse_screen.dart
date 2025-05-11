import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../warehouse/warehouse_management.dart';
import 'register/warehouse_register_screen.dart';
import 'my_warehouse_view_model.dart';

class MyWarehouseScreen extends StatelessWidget {
  const MyWarehouseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MyWarehouseBody();
  }
}

class _MyWarehouseBody extends StatelessWidget {
  const _MyWarehouseBody({super.key});

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
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WarehouseRegisterScreen()),
              );
              if (result == true) {
                await context.read<MyWarehouseViewModel>().refresh();
              }
            },
          ),
        ],
      ),
      body: _buildBody(viewModel, formatter),
    );
  }

  Widget _buildBody(MyWarehouseViewModel viewModel, NumberFormat formatter) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null) {
      return Center(child: Text(viewModel.error!, style: const TextStyle(color: Colors.red)));
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
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: warehouse.images.first,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
              ),
            )
                : const Icon(Icons.home_work, size: 40),
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
  }
}
