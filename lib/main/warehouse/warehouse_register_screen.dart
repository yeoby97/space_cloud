import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../warehouse/my_warehouse_screen.dart';
import '../../data/warehouse.dart';
import '../home/search_screen.dart';

class WarehouseRegisterScreen extends StatefulWidget {
  const WarehouseRegisterScreen({super.key});

  @override
  State<WarehouseRegisterScreen> createState() => _WarehouseRegisterScreenState();
}

class _WarehouseRegisterScreenState extends State<WarehouseRegisterScreen> {
  bool isLoading = false;
  List<XFile>? pickedImages;
  String? address;
  LatLng? location;
  final detailAddressController = TextEditingController();
  final priceController = TextEditingController();
  final numberController = TextEditingController();
  final _priceFormat = NumberFormat("#,###", "en_US");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      _PhotoButton(onTap: _pickImage),
                      _PhotoList(
                        pickedImages: pickedImages,
                        onDelete: (index) {
                          setState(() {
                            pickedImages!.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: selectLocation,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        address ?? '주소',
                        style: TextStyle(
                          fontSize: 20,
                          color: address == null ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(detailAddressController, '상세 주소'),
                  const SizedBox(height: 12),
                  _buildNumberField(priceController, '월 대여료', '₩', _priceFormat),
                  const SizedBox(height: 12),
                  _buildNumberField(numberController, '창고 갯수', '개'),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FloatingActionButton.extended(
                      onPressed: upload,
                      label: const Text("등록", style: TextStyle(fontSize: 16)),
                      icon: const Icon(Icons.check),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text("업로드 중입니다...", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
        ),
        style: const TextStyle(fontSize: 20),
      ),
    );
  }

  Widget _buildNumberField(TextEditingController controller, String hint, String unit, [NumberFormat? formatter]) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: formatter != null
                  ? [
                FilteringTextInputFormatter.digitsOnly,
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final text = newValue.text.replaceAll(',', '');
                  if (text.isEmpty) return newValue.copyWith(text: '');
                  final formatted = formatter.format(int.parse(text));
                  return TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                })
              ]
                  : [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 8),
          Text(unit, style: const TextStyle(fontSize: 20, color: Colors.black)),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    pickedImages = await picker.pickMultiImage();

    if (pickedImages != null && pickedImages!.length > 10) {
      pickedImages = pickedImages!.sublist(0, 10);
    }
    setState(() {});
  }

  void selectLocation() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
    setState(() {
      address = result["address"];
      location = result["location"];
    });
  }

  void upload() async {
    final price = int.tryParse(priceController.text.replaceAll(',', ''));
    final count = int.tryParse(numberController.text);

    if (pickedImages == null || pickedImages!.isEmpty ||
        address == null ||
        location == null ||
        detailAddressController.text.trim().isEmpty ||
        price == null || price <= 0 ||
        count == null || count <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("모든 정보를 올바르게 입력해주세요.")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("로그인이 필요합니다.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final folderName = '${address!}_${detailAddressController.text.trim()}';
      final storageRef = FirebaseStorage.instance.ref().child('warehouses/$folderName');
      List<String> imageUrls = [];

      for (int i = 0; i < pickedImages!.length; i++) {
        final file = File(pickedImages![i].path);
        final uploadRef = storageRef.child('${i + 1}.jpeg');
        await uploadRef.putFile(file);
        final downloadUrl = await uploadRef.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      final warehouse = Warehouse(
        address: address!,
        detailAddress: detailAddressController.text.trim(),
        lat: location!.latitude,
        lng: location!.longitude,
        images: imageUrls,
        price: price,
        count: count,
        createdAt: DateTime.now(),
        ownerId: user.uid,
      );

      await FirebaseFirestore.instance.collection('warehouse').add(warehouse.toMap());

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("등록 실패: $e")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
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
        padding: const EdgeInsets.only(top: 5),
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: const Column(
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
  final void Function(int index) onDelete;

  const _PhotoList({
    super.key,
    required this.pickedImages,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: pickedImages?.asMap().entries.map(
                (entry) {
              final index = entry.key;
              final image = entry.value;

              return Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(File(image.path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => onDelete(index),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ).toList() ?? [],
        ),
      ),
    );
  }
}
