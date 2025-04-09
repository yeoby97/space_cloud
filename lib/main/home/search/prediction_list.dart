import 'package:flutter/material.dart';
import 'package:flutter_google_places_hoc081098/google_maps_webservice_places.dart';

class PredictionList extends StatelessWidget {
  final List<Prediction> predictions;

  const PredictionList({super.key, required this.predictions});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.separated(
        itemCount: predictions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final prediction = predictions[index];
          return ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(prediction.description ?? ""),
            onTap: () {
              Navigator.of(context).pop({
                'placeId': prediction.placeId,
                'description': prediction.description,
              });
            },
          );
        },
      ),
    );
  }
}