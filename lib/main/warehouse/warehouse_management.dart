import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/warehouse.dart';

class WarehouseManagement extends StatefulWidget {
  final Warehouse warehouse;
  const WarehouseManagement({super.key, required this.warehouse});

  @override
  State<WarehouseManagement> createState() => _WarehouseManagementState();
}

class _WarehouseManagementState extends State<WarehouseManagement> {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  DateTime? startDate;
  DateTime? endDate;

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate ?? now,
      firstDate: startDate ?? now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => endDate = picked);
  }

  Future<void> _addUnavailablePeriod() async {
    if (startDate == null || endDate == null) return;
    if (endDate!.isBefore(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종료일은 시작일보다 이후여야 합니다.')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('warehouse')
        .doc(widget.warehouse.id)
        .collection('unavailable')
        .add({
      'start': startDate!.toIso8601String(),
      'end': endDate!.toIso8601String(),
    });

    setState(() {
      startDate = null;
      endDate = null;
    });
  }

  Stream<QuerySnapshot> _getUnavailablePeriods() {
    return FirebaseFirestore.instance
        .collection('warehouse')
        .doc(widget.warehouse.id)
        .collection('unavailable')
        .orderBy('start')
        .snapshots();
  }

  Stream<QuerySnapshot> _getSpaces() {
    return FirebaseFirestore.instance
        .collection('warehouse')
        .doc(widget.warehouse.id)
        .collection('spaces')
        .snapshots();
  }

  Future<String> _getUserName(String uid) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc.data()?['displayName'] ?? '알 수 없음';
  }

  Widget _buildLayoutGrid(Map<String, dynamic> spaceStatus) {
    final rows = widget.warehouse.layout['rows'] as int;
    final cols = widget.warehouse.layout['columns'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('창고 배치도 (사용 중인 공간은 회색)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Column(
          children: List.generate(rows, (r) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(cols, (c) {
                final spaceId = '${String.fromCharCode(65 + r)}${c + 1}';
                final isInUse = spaceStatus[spaceId] ?? false;

                return Container(
                  margin: const EdgeInsets.all(4),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isInUse ? Colors.grey[400] : Colors.green[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(spaceId, style: const TextStyle(fontSize: 10)),
                );
              }),
            );
          }),
        ),
      ],
    );
  }

  Future<Map<String, bool>> _fetchCurrentSpaceStatus(Map<String, bool> ans) async {
    return ans;
  }

  @override
  Widget build(BuildContext context) {
    Map<String, bool> usageMap = {};

    return Scaffold(
      appBar: AppBar(title: const Text('창고 관리')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.warehouse.address, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.warehouse.detailAddress),
            const Divider(height: 32),
            FutureBuilder<Map<String, bool>>(
              future: _fetchCurrentSpaceStatus(usageMap),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildLayoutGrid(snapshot.data!);
              },
            ),
            const Divider(height: 32),
            const Text('전체 예약 내역', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getSpaces(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final spaces = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: spaces.length,
                    itemBuilder: (context, index) {
                      final space = spaces[index];
                      final spaceId = space['spaceId'];

                      return FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('warehouse')
                            .doc(widget.warehouse.id)
                            .collection('spaces')
                            .doc(space.id)
                            .collection('reservations')
                            .orderBy('start', descending: true)
                            .get(),
                        builder: (context, resSnap) {
                          if (!resSnap.hasData) return const SizedBox();

                          final reservations = resSnap.data!.docs;
                          if (reservations.isEmpty) {
                            usageMap[spaceId] = false;
                            return ListTile(title: Text('$spaceId (예약 없음)'));
                          }

                          final latest = reservations.first;
                          final start = DateTime.parse(latest['start']);
                          final end = DateTime.parse(latest['end']);
                          final reservedBy = latest['reservedBy'];
                          final now = DateTime.now();
                          final isInUse = start.isBefore(now) && end.isAfter(now);
                          if (isInUse) {
                            usageMap[spaceId] = true;
                          }

                          return FutureBuilder<String>(
                            future: _getUserName(reservedBy),
                            builder: (context, nameSnap) {
                              final userName = nameSnap.data ?? '예약자';
                              return ListTile(
                                tileColor: isInUse ? Colors.grey[200] : null,
                                title: Text('$spaceId - $userName'),
                                subtitle: Text('${_dateFormat.format(start)} ~ ${_dateFormat.format(end)}'),
                                trailing: isInUse
                                    ? const Text('사용 중', style: TextStyle(color: Colors.red))
                                    : null,
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
