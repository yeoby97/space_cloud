import 'package:cloud_firestore/cloud_firestore.dart';

class Warehouse {
  final String id;
  final String address;
  final String detailAddress;
  final int count;
  final DateTime? createdAt;
  final List<String> images;
  final double lat;
  final double lng;
  final int price;
  final String ownerId;
  final Map<String, dynamic> layout;

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
    required this.ownerId,
    required this.layout,
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
      ownerId: data['ownerId'] ?? '',
      layout: Map<String, dynamic>.from(data['layout'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'detailAddress': detailAddress,
      'count': count,
      'createdAt': FieldValue.serverTimestamp(),
      'images': images,
      'lat': lat,
      'lng': lng,
      'price': price,
      'ownerId': ownerId,
      'layout': layout,
    };
  }

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'] ?? '',
      address: json['address'] ?? '',
      detailAddress: json['detailAddress'] ?? '',
      price: json['price'] ?? 0,
      count: json['count'] ?? 0,
      images: List<String>.from(json['images'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      layout: Map<String, dynamic>.from(json['layout'] ?? {}),
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      ownerId: json['ownerId'] ?? '',
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'detailAddress': detailAddress,
      'price': price,
      'count': count,
      'images': images,
      'createdAt': createdAt?.toIso8601String(),
      'layout': layout,
      'lat': lat,
      'lng': lng,
      'ownerId': ownerId,
    };
  }

}
