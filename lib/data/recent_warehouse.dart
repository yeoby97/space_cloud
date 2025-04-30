class RecentWarehouse {
  final String id;
  final String address;
  final String imageUrl;
  final DateTime viewedAt;

  RecentWarehouse({
    required this.id,
    required this.address,
    required this.imageUrl,
    required this.viewedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address': address,
      'imageUrl': imageUrl,
      'viewedAt': viewedAt.toIso8601String(),
    };
  }

  factory RecentWarehouse.fromMap(Map<String, dynamic> map) {
    return RecentWarehouse(
      id: map['id'],
      address: map['address'],
      imageUrl: map['imageUrl'],
      viewedAt: DateTime.parse(map['viewedAt']),
    );
  }
}
