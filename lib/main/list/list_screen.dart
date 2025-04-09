import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final List<DocumentSnapshot> _warehouseDocs = [];
  final List<DocumentSnapshot> _reservationDocs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final reservations = await FirebaseFirestore.instance
        .collectionGroup('reservations')
        .where('reservedBy', isEqualTo: user.uid)
        .get();

    final List<DocumentSnapshot> warehouses = [];
    final List<DocumentSnapshot> reservationsList = [];

    for (var reservation in reservations.docs) {
      final spaceRef = reservation.reference.parent.parent;
      final warehouseRef = spaceRef?.parent.parent;

      if (warehouseRef != null) {
        final warehouseDoc = await warehouseRef.get();
        warehouses.add(warehouseDoc);
        reservationsList.add(reservation);
      }
    }

    setState(() {
      _warehouseDocs.clear();
      _warehouseDocs.addAll(warehouses);
      _reservationDocs.clear();
      _reservationDocs.addAll(reservationsList);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("사용 중인 창고")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _reservationDocs.length,
        itemBuilder: (_, index) {
          final reservation = _reservationDocs[index].data() as Map<String, dynamic>;
          final warehouse = _warehouseDocs[index].data() as Map<String, dynamic>;

          final start = _parseDate(reservation['start']);
          final end = _parseDate(reservation['end']);
          final address = warehouse['address'] ?? '';
          final detail = warehouse['detailAddress'] ?? '';
          final images = List<String>.from(warehouse['images'] ?? []);

          return _buildWarehouseCard(address, detail, start, end, images);
        },
      ),
    );
  }

  Widget _buildWarehouseCard(
      String address,
      String detailAddress,
      DateTime start,
      DateTime end,
      List<String> imageUrls,
      ) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(
                  imageUrls.first,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(detailAddress, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        '${_formatDate(start)} ~ ${_formatDate(end)}',
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
