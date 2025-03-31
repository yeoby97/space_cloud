import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:space_cloud/main/warehouse/warehouse_register_screen.dart';
import '../../data/warehouse.dart';
import '../warehouse/warehouse_detail.dart';

class MyWarehouseScreen extends StatelessWidget {
  const MyWarehouseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
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
      body: user == null
          ? const Center(child: Text('로그인이 필요합니다.'))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('warehouse')
            .where('ownerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('에러 발생: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          final warehouses = docs.map((doc) => Warehouse.fromDoc(doc)).toList();

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
                        builder: (_) => WarehouseDetail(warehouse: warehouse),
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