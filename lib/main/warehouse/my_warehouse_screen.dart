import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../warehouse/warehouse_management.dart';
import 'register/warehouse_register_screen.dart';
import 'my_warehouse_view_model.dart';

class MyWarehouseScreen extends StatefulWidget {
  const MyWarehouseScreen({super.key});

  @override
  State<MyWarehouseScreen> createState() => _MyWarehouseScreenState();
}

class _MyWarehouseScreenState extends State<MyWarehouseScreen> {
  late MyWarehouseViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = MyWarehouseViewModel();
    viewModel.loadOnce();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: const _MyWarehouseBody(),
    );
  }
}

class _MyWarehouseBody extends StatefulWidget {
  const _MyWarehouseBody({super.key});

  @override
  State<_MyWarehouseBody> createState() => _MyWarehouseBodyState();
}

class _MyWarehouseBodyState extends State<_MyWarehouseBody> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<MyWarehouseViewModel>().loadOnce();
  }

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

              // 등록 완료 후 새로고침
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
                ? Image.network(
              warehouse.images.first,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
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
