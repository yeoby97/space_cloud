import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:space_cloud/main/home/search/prediction_list.dart';
import 'package:space_cloud/main/home/search/search_input.dart';
import 'package:space_cloud/main/home/search/warehouse_list.dart';
import 'search_view_model.dart';

const String kNaverClientId = 'mvYdH_wuPj6tN_unynKa';
const String kNaverClientSecret = 'pudRWNUqH3';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchViewModel(kNaverClientId, kNaverClientSecret)..loadNearbyWarehouses(),
      child: const _SearchScreenBody(),
    );
  }
}

class _SearchScreenBody extends StatelessWidget {
  const _SearchScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<SearchViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SearchInput(
                controller: model.controller,
                onChanged: model.onChanged,
              ),
              const SizedBox(height: 10),

              if (model.predictions.isNotEmpty)
                Expanded(
                  child: PredictionList(predictions: model.predictions),
                ),
              Expanded(
                child: WarehouseList(
                  warehouses: model.nearbyPlaces,
                  loading: model.isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
