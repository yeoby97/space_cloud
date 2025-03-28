import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

class SearchScreen extends StatefulWidget {

  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController controller = TextEditingController();
  String? selectedAddress;
  String? selectedLatLng;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView( // 스크롤 가능하게
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            placesAutoCompleteTextField(),
          ],
        ),
      ),
    );
  }

  placesAutoCompleteTextField() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          child: GooglePlaceAutoCompleteTextField(
            boxDecoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2), // 그림자 색상
                  blurRadius: 10,   // 흐림 정도
                  spreadRadius: 2,  // 그림자 확산 정도
                  offset: Offset(3, 3), // X, Y 방향 위치 조정
                ),
              ],
              borderRadius: BorderRadius.circular(10.0),
            ),
            textEditingController: controller,
            googleAPIKey: 'AIzaSyAuhd1aQTSgjtgnydP3_wgD3SDD2QD-VGU',
            inputDecoration: InputDecoration(
              hintText: "Search your location",
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
            debounceTime: 200,
            countries: ["kr"],
            language: "ko",
            isLatLngRequired: true,
            getPlaceDetailWithLatLng: (Prediction prediction) {
              LatLng location = LatLng(
                double.parse(prediction.lat ?? "0.0"),
                double.parse(prediction.lng ?? "0.0"),
              );
              Navigator.of(context).pop(location);
            },
            itemClick: (Prediction prediction) {
              controller.text = prediction.description ?? "";
            },
            seperatedBuilder: Divider(),
            containerHorizontalPadding: 10,
            itemBuilder: (context, index, Prediction prediction) {
              return Container(
                padding: EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(Icons.location_on),
                    SizedBox(width: 7),
                    Expanded(child: Text("${prediction.description ?? ""}"))
                  ],
                ),
              );
            },
            isCrossBtnShown: true,
          ),
        ),
      ),
    );
  }
}
