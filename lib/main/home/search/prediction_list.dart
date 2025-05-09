import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:http/http.dart' as http;

class PredictionList extends StatelessWidget {
  final List<Map<String, dynamic>> predictions;

  const PredictionList({super.key, required this.predictions});

  @override
  Widget build(BuildContext context) {
    if (predictions.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: predictions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final prediction = predictions[index];
        final title = prediction['title']?.toString() ?? '';
        final address = prediction['address']?.toString() ?? '';
        final mapx = prediction['mapx'] as double? ?? 0.0;
        final mapy = prediction['mapy'] as double? ?? 0.0;

        return ListTile(
          leading: const Icon(Icons.location_on),
          title: Text(title.isNotEmpty ? title : address),
          onTap: () async {
            final coord = await convertTM128toWGS84(mapx, mapy);
            if (coord != null) {
              Navigator.of(context).pop({
                'address': address,
                'location': LatLng(coord['lat']!, coord['lng']!),
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('좌표를 변환할 수 없습니다.')),
              );
            }
          },
        );
      },
    );
  }

  Map<String, double> convertTM128toWGS84(double mapx, double mapy) {
    final lng = 1e-7 * mapx;
    final lat = 1e-7 * mapy;
    return {'lat': lat, 'lng': lng};
  }
}
