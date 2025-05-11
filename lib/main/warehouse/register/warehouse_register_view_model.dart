import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/warehouse.dart';
import '../../home/search/search_screen.dart';

class RegisterViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isLayout = false;
  bool get isLayout => _isLayout;

  void toggleLayout() {
    _isLayout = !_isLayout;
    notifyListeners();
  }

  void startLoading() {
    _isLoading = true;
    notifyListeners();
  }

  List<XFile> _images = [];
  List<XFile> get images => _images;

  void deletePhoto(int index) {
    _images.removeAt(index);
    notifyListeners();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final newImages = await picker.pickMultiImage();

    if (newImages.isNotEmpty) {
      _images = _images + newImages;
      if (_images.length > 10) {
        _images = _images.sublist(0, 10);
      }
    }
    notifyListeners();
  }

  String? address;
  LatLng? location;

  void selectLocation(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
    address = result["address"];
    location = result["location"];
    notifyListeners();
  }

  String? detailAddress;
  final priceController = TextEditingController();
  int? price;

  final countController = TextEditingController();
  final countFocusNode = FocusNode();
  int? _count;
  int? get count => _count;
  void countChange(int? value) {
    _count = value;
    clearBox();
    notifyListeners();
  }

  final rowController = TextEditingController();
  final rowFocusNode = FocusNode();
  int? _row;
  int? get row => _row;
  void rowChange(int? value) {
    _row = value;
    clearBox();
    notifyListeners();
  }

  final colController = TextEditingController();
  final colFocusNode = FocusNode();
  int? _col;
  int? get col => _col;
  void colChange(int? value) {
    _col = value;
    clearBox();
    notifyListeners();
  }

  List<(int, int)> _pickedBox = [];
  List<(int, int)> get pickedBox => _pickedBox;

  void touchBox(int row, int col) {
    if (isBoxSelected(row, col)) {
      removeBox(row, col);
    } else if (_pickedBox.length < count!) {
      addBox(row, col);
    }
  }

  void addBox(int row, int col) {
    _pickedBox.add((row, col));
    notifyListeners();
  }

  void removeBox(int row, int col) {
    _pickedBox.remove((row, col));
    notifyListeners();
  }

  void clearBox() {
    _pickedBox.clear();
    notifyListeners();
  }

  bool isBoxSelected(int row, int col) {
    return _pickedBox.contains((row, col));
  }

  void dispose() {
    super.dispose();
    priceController.dispose();
    countController.dispose();
    countFocusNode.dispose();
    rowController.dispose();
    rowFocusNode.dispose();
    colController.dispose();
    colFocusNode.dispose();
  }

  void upload(BuildContext context) async {
    final address = this.address;
    final location = this.location;
    if (address == null || location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("주소를 선택해주세요.")),
      );
      return;
    }

    final detailAddress = this.detailAddress;
    if (detailAddress == null || detailAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("상세 주소를 입력해주세요.")),
      );
      return;
    }

    final price = int.tryParse(priceController.text.replaceAll(',', ''));
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("월 대여료를 올바르게 입력해주세요.")),
      );
      return;
    }

    final count = int.tryParse(countController.text);
    if (count == null || count <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("창고 갯수를 올바르게 입력해주세요.")),
      );
      return;
    }

    final rows = int.tryParse(rowController.text);
    if (rows == null || rows <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("행을 올바르게 입력해주세요.")),
      );
      return;
    }

    final columns = int.tryParse(colController.text);
    if (columns == null || columns <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("열을 올바르게 입력해주세요.")),
      );
      return;
    }

    final pickedImages = images;
    if (pickedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("사진을 선택해주세요.")),
      );
      return;
    }

    if (_pickedBox.length != count) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("선택한 상자 수가 맞지 않습니다.")),
      );
      return;
    }

    final FirebaseAuth auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("로그인이 필요합니다.")),
      );
      return;
    }

    startLoading();

    try {
      final warehouseRoot = FirebaseFirestore.instance.collection('warehouse');
      final existingDocs = await warehouseRoot.where('address', isEqualTo: address).get();
      DocumentReference docRef;

      if (existingDocs.docs.isNotEmpty) {
        docRef = existingDocs.docs.first.reference;
      } else {
        docRef = warehouseRoot.doc();
        await docRef.set({'address': address});
      }

      List<String> imageUrls = [];
      for (final image in pickedImages) {
        final ref = FirebaseStorage.instance.ref('warehouses/${docRef.id}/${image.name}');
        await ref.putFile(File(image.path));
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      final warehouse = Warehouse(
        address: address,
        detailAddress: detailAddress,
        count: count,
        createdAt: DateTime.now(),
        images: imageUrls,
        lat: location.latitude,
        lng: location.longitude,
        price: price,
        ownerId: user.uid,
        layout: {
          'rows': rows,
          'columns': columns,
          'boxes': _pickedBox.map((e) => {'row': e.$1, 'col': e.$2}).toList(),
        },
      );

      await docRef.collection('warehouses').add(warehouse.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("창고가 성공적으로 등록되었습니다.")),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("등록 중 오류 발생: $e")),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  RegisterViewModel();

  get warehouse => null;
}
