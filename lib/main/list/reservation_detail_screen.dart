// TODO : 최적화 및 상태 최상단화

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReservationDetailPage extends StatelessWidget {
  final Map<String, dynamic> warehouse;
  final Map<String, dynamic> space;
  final Map<String, dynamic> reservation;

  const ReservationDetailPage({
    Key? key,
    required this.warehouse,
    required this.space,
    required this.reservation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final address = warehouse['address'] ?? '';
    final detailAddress = warehouse['detailAddress'] ?? '';
    final spaceName = space['spaceId'] ?? '';
    final imageUrls = List<String>.from(warehouse['images'] ?? []);
    final startDate = _parseDate(reservation['start']);
    final endDate = _parseDate(reservation['end']);

    return Scaffold(
      appBar: AppBar(
        title: Text('예약 상세'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrls[0],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            SizedBox(height: 16),
            Text("주소: $address", style: TextStyle(fontSize: 16)),
            Text("상세주소: $detailAddress", style: TextStyle(fontSize: 16)),
            Text("공간 이름: $spaceName", style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            Text("기간: ${_formatDate(startDate)} ~ ${_formatDate(endDate)}", style: TextStyle(fontSize: 16)),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                // 예약 취소 로직 (예: Firestore 삭제 등)
                // 나중에 구현해도 됨
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text("예약 취소"),
            )
          ],
        ),
      ),
    );
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

  String _formatDate(DateTime date) {
    return "${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}";
  }
}