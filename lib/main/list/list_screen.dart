// TODO : 최적화 및 상태 최상단화

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:space_cloud/main/list/reservation_detail_screen.dart';

class ListScreen extends StatefulWidget {

  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreen();
}

class _ListScreen extends State<ListScreen> {

  List<DocumentSnapshot> _warehouseDocs = [];
  List<DocumentSnapshot> _spaceDocs = [];
  List<DocumentSnapshot> _reservationDocs = [];
  bool _isLoading = true;
  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    _loadReservedSpaces();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("사용 중인 창고"),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _reservationDocs.length,
        itemBuilder: (context, index) {
          final warehouse = _warehouseDocs[index].data() as Map<String, dynamic>;
          final reservation = _reservationDocs[index].data() as Map<String, dynamic>;
          final space = _spaceDocs[index].data() as Map<String, dynamic>;

          final address = warehouse['address'] ?? '';
          final detailAddress = warehouse['detailAddress'] ?? '';
          final spaceName = space['spaceId'] ?? '';
          final imageUrls = List<String>.from(warehouse['images'] ?? []);
          final startDate = _parseDate(reservation['start']);
          final endDate = _parseDate(reservation['end']);
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReservationDetailPage(
                    warehouse: warehouse,
                    space: space,
                    reservation: reservation,
                  ),
                ),
              );
            },
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReservationDetailPage(
                      warehouse: warehouse,
                      space: space,
                      reservation: reservation,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageUrls.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              imageUrls[0],
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                          ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                address,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                detailAddress,
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                spaceName,
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "${_formatDate(startDate)} ~ ${_formatDate(endDate)}",
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );

        },
      ),
    );
  }

  Future<void> _loadReservedSpaces() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final querySnapshot = await FirebaseFirestore.instance
        .collectionGroup('reservations')
        .where('reservedBy', isEqualTo: currentUser!.uid)
        .get();

    List<DocumentSnapshot> warehouses = [];
    List<DocumentSnapshot> spaces = [];
    List<DocumentSnapshot> reservations = [];

    for (var reservationDoc in querySnapshot.docs) {
      final reservationRef = reservationDoc.reference;
      final spaceRef = reservationRef.parent.parent;
      final warehouseRef = spaceRef?.parent.parent;

      if (spaceRef != null && warehouseRef != null) {
        reservations.add(reservationDoc);

        final spaceDoc = await spaceRef.get();
        spaces.add(spaceDoc);

        final warehouseDoc = await warehouseRef.get();
        warehouses.add(warehouseDoc);
      }
    }

    setState(() {
      _reservationDocs = reservations;
      _spaceDocs = spaces;
      _warehouseDocs = warehouses;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    return "${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}";
  }

  DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else {
      return DateTime.now();
    }
  }
}
