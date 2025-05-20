import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/warehouse.dart';
import '../../home/search/search_screen.dart';
import 'blueprint/line.dart';

class RegisterViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isLoading = false;
  bool _isLayout = false;
  List<XFile> _images = [];
  String? address;
  LatLng? location;
  String? detailAddress;
  final priceController = TextEditingController();
  int? price;
  final countController = TextEditingController();
  final countFocusNode = FocusNode();
  int? _count;
  bool _isDraw = false;
  final rowController = TextEditingController();
  final rowFocusNode = FocusNode();
  int? _row;
  final colController = TextEditingController();
  final colFocusNode = FocusNode();
  int? _col;
  final List<(int, int)> _pickedBox = [];
  final _lines = <Line>[];
  final Set<Offset> _doors = {};

  bool get isDraw => _isDraw;
  bool get isLoading => _isLoading;
  bool get isLayout => _isLayout;
  List<XFile> get images => _images;
  int? get count => _count;
  int? get row => _row;
  int? get col => _col;
  List<(int, int)> get pickedBox => _pickedBox;
  List<Line> get lines => _lines;
  Set<Offset> get doors => _doors;

  void toggleLayout() {
    _isLayout = !_isLayout;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void deletePhoto(int index) {
    _images.removeAt(index);
    notifyListeners();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final newImages = await picker.pickMultiImage();

    if (newImages.isNotEmpty) {
      _images = (_images + newImages).take(10).toList();
      notifyListeners();
    }
  }

  void selectLocation(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
    if (result != null && context.mounted) {
      address = result["address"];
      location = result["location"];
      notifyListeners();
    }
  }

  void countChange(int? value) {
    _count = value;
    clearBox();
    notifyListeners();
  }

  void drawChange(bool value) {
    _isDraw = value;
    notifyListeners();
  }

  void rowChange(int? value) {
    _row = value;
    clearBox();
    notifyListeners();
  }


  void colChange(int? value) {
    _col = value;
    clearBox();
    notifyListeners();
  }


  void touchBox(int row, int col) {
    if (isBoxSelected(row, col)) {
      removeBox(row, col);
    } else if (_pickedBox.length < (_count ?? 0)) {
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

  bool isBoxSelected(int row, int col) => _pickedBox.contains((row, col));

  @override
  void dispose() {
    priceController.dispose();
    countController.dispose();
    countFocusNode.dispose();
    rowController.dispose();
    rowFocusNode.dispose();
    colController.dispose();
    colFocusNode.dispose();
    super.dispose();
  }

  Future<void> upload(BuildContext context) async {
    if (!_validateInputs(context)) return;

    _setLoading(true);

    try {
      final user = _auth.currentUser!;
      final warehouseRoot = _firestore.collection('warehouse');

      final existingDocs = await warehouseRoot
          .where('lat', isEqualTo: location!.latitude)
          .where('lng', isEqualTo: location!.longitude)
          .get();
      DocumentReference docRef;

      if (existingDocs.docs.isNotEmpty) {
        docRef = existingDocs.docs.first.reference;
      } else {
        docRef = warehouseRoot.doc();
        await docRef.set({'lat': location!.latitude, 'lng': location!.longitude});
      }

      final imageUrls = await Future.wait(_images.map((image) async {
        final ref = _storage.ref('warehouses/${docRef.id}/${image.name}');
        await ref.putFile(File(image.path));
        return await ref.getDownloadURL();
      }));

      final warehouse = Warehouse(
        address: address!,
        detailAddress: detailAddress!,
        count: _count!,
        createdAt: DateTime.now(),
        images: imageUrls,
        lat: location!.latitude,
        lng: location!.longitude,
        price: price!,
        ownerId: user.uid,
        layout: {
          'rows': _row,
          'columns': _col,
          'boxes': _pickedBox.map((e) => {'row': e.$1, 'col': e.$2}).toList(),
        },
      );

      await docRef.collection('warehouses').add(warehouse.toMap());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("창고가 성공적으로 등록되었습니다.")),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("등록 중 오류 발생: $e")),
        );
      }
    } finally {
      _setLoading(false);
    }
  }

  bool _validateInputs(BuildContext context) {
    if (address == null || location == null) {
      _showMessage(context, "주소를 선택해주세요.");
      return false;
    }
    if (detailAddress == null || detailAddress!.isEmpty) {
      _showMessage(context, "상세 주소를 입력해주세요.");
      return false;
    }
    price = int.tryParse(priceController.text.replaceAll(',', ''));
    if (price == null || price! <= 0) {
      _showMessage(context, "월 대여료를 올바르게 입력해주세요.");
      return false;
    }
    _count = int.tryParse(countController.text);
    if (_count == null || _count! <= 0) {
      _showMessage(context, "창고 갯수를 올바르게 입력해주세요.");
      return false;
    }
    _row = int.tryParse(rowController.text);
    if (_row == null || _row! <= 0) {
      _showMessage(context, "행을 올바르게 입력해주세요.");
      return false;
    }
    _col = int.tryParse(colController.text);
    if (_col == null || _col! <= 0) {
      _showMessage(context, "열을 올바르게 입력해주세요.");
      return false;
    }
    if (_images.isEmpty) {
      _showMessage(context, "사진을 선택해주세요.");
      return false;
    }
    if (_pickedBox.length != _count) {
      _showMessage(context, "선택한 상자 수가 맞지 않습니다.");
      return false;
    }
    if (_auth.currentUser == null) {
      _showMessage(context, "로그인이 필요합니다.");
      return false;
    }
    return true;
  }

  void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  RegisterViewModel();

  get warehouse => null;
}
