// // TODO : 최적화 및 상태 최상단화
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
//
// class UsageHistoryScreen extends StatefulWidget {
//
//   UsageHistoryScreen({super.key});
//
//   @override
//   State<UsageHistoryScreen> createState() => _UsageHistoryScreenState();
// }
//
// class _UsageHistoryScreenState extends State<UsageHistoryScreen> {
//
//   List<DocumentSnapshot> _warehouseDocs = [];
//   List<DocumentSnapshot> _spaceDocs = [];
//   List<DocumentSnapshot> _reservationDocs = [];
//   bool _isLoading = true;
//   User? user = FirebaseAuth.instance.currentUser;
//
//   @override
//   void initState() {
//     _loadReservedSpaces();
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("사용 중인 창고"),
//       ),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator())
//           : ListView.builder(
//         itemCount: _reservationDocs.length,
//         itemBuilder: (context, index) {
//           final warehouse = _warehouseDocs[index].data() as Map<String, dynamic>;
//           final reservation = _reservationDocs[index].data() as Map<String, dynamic>;
//
//           final address = warehouse['address'] ?? '';
//           final detailAddress = warehouse['detailAddress'] ?? '';
//           final imageUrls = List<String>.from(warehouse['images'] ?? []);
//           final startDate = _parseDate(reservation['start']);
//           final endDate = _parseDate(reservation['end']);
//           print(imageUrls[0]);
//           return Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Card(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(15),
//               ),
//               elevation: 3,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // 이미지 영역
//                   if (imageUrls.isNotEmpty)
//                     ClipRRect(
//                       borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
//                       child: Image.network(
//                         imageUrls[0],
//                         height: 180,
//                         width: double.infinity,
//                         fit: BoxFit.contain,
//                       ),
//                     ),
//
//                   // 정보 영역
//                   Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           address,
//                           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                         ),
//                         SizedBox(height: 4),
//                         Text(
//                           detailAddress,
//                           style: TextStyle(fontSize: 14, color: Colors.grey[700]),
//                         ),
//                         SizedBox(height: 12),
//                         Row(
//                           children: [
//                             Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
//                             SizedBox(width: 6),
//                             Text(
//                               "${_formatDate(startDate)} ~ ${_formatDate(endDate)}",
//                               style: TextStyle(fontSize: 14, color: Colors.black87),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Future<void> _loadReservedSpaces() async {
//     final currentUser = FirebaseAuth.instance.currentUser;
//     final querySnapshot = await FirebaseFirestore.instance
//         .collectionGroup('reservations')
//         .where('reservedBy', isEqualTo: currentUser!.uid)
//         .get();
//
//     List<DocumentSnapshot> warehouses = [];
//     List<DocumentSnapshot> spaces = [];
//     List<DocumentSnapshot> reservations = [];
//
//     for (var reservationDoc in querySnapshot.docs) {
//       print("존재함");
//       final reservationRef = reservationDoc.reference;
//       final spaceRef = reservationRef.parent.parent;
//       final warehouseRef = spaceRef?.parent.parent;
//
//       if (spaceRef != null && warehouseRef != null) {
//         // 예약 문서 추가
//         reservations.add(reservationDoc);
//
//         // 공간 문서 가져오기
//         final spaceDoc = await spaceRef.get();
//         spaces.add(spaceDoc);
//
//         // 창고 문서 가져오기
//         final warehouseDoc = await warehouseRef.get();
//         warehouses.add(warehouseDoc);
//       }
//     }
//
//     setState(() {
//       _reservationDocs = reservations;
//       _spaceDocs = spaces;
//       _warehouseDocs = warehouses;
//       _isLoading = false;
//     });
//   }
//
//   String _formatDate(DateTime date) {
//     return "${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}";
//   }
//
//   DateTime _parseDate(dynamic value) {
//     if (value is Timestamp) {
//       return value.toDate();
//     } else if (value is String) {
//       return DateTime.parse(value);
//     } else {
//       return DateTime.now(); // fallback
//     }
//   }
// }
