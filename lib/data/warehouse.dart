import 'package:cloud_firestore/cloud_firestore.dart';

class Warehouse {
  final String id; // Firestore에 저장할 땐 제외해도 됨
  final String address;
  final String detailAddress;
  final int count;
  final DateTime? createdAt;
  final List<String> images;
  final double lat;
  final double lng;
  final int price;

  Warehouse({
    this.id = '',
    required this.address,
    required this.detailAddress,
    required this.count,
    required this.createdAt,
    required this.images,
    required this.lat,
    required this.lng,
    required this.price,
  });

  factory Warehouse.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Warehouse(
      id: doc.id,
      address: data['address'] ?? '',
      detailAddress: data['detailAddress'] ?? '',
      count: data['count'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      images: List<String>.from(data['images'] ?? []),
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      price: data['price'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'detailAddress': detailAddress,
      'count': count,
      'createdAt': FieldValue.serverTimestamp(), // 서버 타임스탬프 직접 지정
      'images': images,
      'lat': lat,
      'lng': lng,
      'price': price,
    };
  }
}