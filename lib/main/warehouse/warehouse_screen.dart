import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../home/search_screen.dart';

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  bool isLoading = false;
  List<XFile>? pickedImages;
  String? address;
  LatLng? location;
  TextEditingController detailAddressController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController numberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                spacing: 20,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 30,
                  ),
                  Row(
                    spacing: 10,
                    children: [
                      _PhotoButton(onTap: _pickImage),
                      _PhotoList(pickedImages: pickedImages),
                    ],
                  ),
                  GestureDetector(
                    onTap: selectLocation,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        address ?? '주소',
                        style: TextStyle(
                          fontSize: 20,
                          color: address == null ? Colors.grey : Colors.black, // 조건에 따라 색상 변경
                        ),
                        softWrap: true,
                        maxLines: null,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: detailAddressController,
                      decoration: InputDecoration(
                        hintText: '상세 주소',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none, // 테두리 제거 (Container에서 처리)
                      ),
                      style: TextStyle(fontSize: 20),
                      maxLines: null,
                    ),
                  ),
                  Container(
                    width: 200,
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number, // 숫자 키패드
                            decoration: InputDecoration(
                              hintText: '월 대여료',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(fontSize: 20),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: 8), // ₩ 기호와 입력창 사이 간격
                        Text(
                          '₩',
                          style: TextStyle(fontSize: 20, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 200,
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [ // ₩ 기호와 입력창 사이 간격
                        Expanded(
                          child: TextField(
                            controller: numberController,
                            keyboardType: TextInputType.number, // 숫자 키패드
                            decoration: InputDecoration(
                              hintText: '창고 갯수',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(fontSize: 20),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '개',
                          style: TextStyle(fontSize: 20, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity, // 가로 전체 너비
                    child: FloatingActionButton.extended(
                      onPressed: upload,
                      label: Text(
                        "등록",
                        style: TextStyle(fontSize: 16),
                      ),
                      icon: Icon(Icons.check),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 로딩 오버레이
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "업로드 중입니다...",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    pickedImages = await picker.pickMultiImage();

    if(pickedImages != null){
      if(pickedImages!.length > 10){
        pickedImages = pickedImages!.sublist(0, 10);
      }
      setState(() {});
    }
  }

  void selectLocation() async{
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return SearchScreen();
        },
      ),
    );
    setState(() {
      address = result["address"];
      location = result["location"];
    });
  }

  void upload() async{
    print("진행중");
    if (pickedImages == null || pickedImages!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("사진을 선택해주세요.")));
      return;
    }
    if (address == null || detailAddressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("주소와 상세주소를 입력해주세요.")));
      return;
    }
    print("진행중");
    setState(() {
      isLoading = true;
    });
    try {
      final folderName = '${address!}_${detailAddressController.text.trim()}';
      final storageRef = FirebaseStorage.instance.ref().child('warehouses/$folderName');
      List<String> imageUrls = [];

      for (int i = 0; i < pickedImages!.length; i++) {
        final XFile image = pickedImages![i];
        final File file = File(image.path);

        // 저장 경로: warehouses/주소_상세주소/1.jpeg, 2.jpeg ...
        final uploadRef = storageRef.child('${i + 1}.jpeg');

        // 업로드
        final uploadTask = await uploadRef.putFile(file);
        final downloadUrl = await uploadRef.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      // Firestore 저장
      await FirebaseFirestore.instance.collection('warehouse').add({
        'address': address,
        'detailAddress': detailAddressController.text.trim(),
        'lat' : location!.latitude,
        'lng' : location!.longitude,
        'images': imageUrls,
        'price': int.tryParse(priceController.text) ?? 1000000,
        'count': int.tryParse(numberController.text) ?? 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("등록 완료!")));
    } catch (e) {
      print('업로드 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("등록 실패: $e")));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        Navigator.of(context).pop();
      }
    }
  }
}

class _PhotoButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PhotoButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(0, 5, 0, 0),
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_outlined, size: 28),
            SizedBox(height: 4),
            Text('0/10', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _PhotoList extends StatelessWidget {
  final List<XFile>? pickedImages;

  const _PhotoList({super.key, required this.pickedImages});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 10,
          children: pickedImages != null ?
          pickedImages!.map(
                (image) =>
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(File(image.path)), // 이미지 파일 경로로 표시
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
          ).toList() : [],
        ),
      ),
    );
  }
}
