import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../home/search/search_screen.dart';

class RegisterViewModel extends ChangeNotifier {


  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isLayout = false;
  bool get isLayout => _isLayout;
  void toggleLayout(){
    _isLayout = !_isLayout;
    notifyListeners();
  }

  void startLoading() {
    _isLoading = true;
    notifyListeners();
  }

  List<XFile> _images = [];
  List<XFile> get images => _images;

  void deletePhoto(int index){
    _images.removeAt(index);
    notifyListeners();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final newImages = await picker.pickMultiImage();


    if (newImages.isNotEmpty) {
      _images = _images + newImages;

      // 10장 넘으면 앞에서부터 자르기 (뒤에 선택한 게 우선이므로 뒤에서부터 남겨둠)
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
  void countChange(int? value){
    _count = value;
    clearBox();
    notifyListeners();
  }

  final rowController = TextEditingController();
  final rowFocusNode = FocusNode();
  int? _row;
  int? get row => _row;
  void rowChange(int? value){
    _row = value;
    clearBox();
    notifyListeners();
  }

  final colController = TextEditingController();
  final colFocusNode = FocusNode();
  int? _col;
  int? get col => _col;
  void colChange(int? value){
    _col = value;
    clearBox();
    notifyListeners();
  }

  List<(int, int)> _pickedBox = [];
  List<(int, int)> get pickedBox => _pickedBox;

  void touchBox(int row,int col){
    if(isBoxSelected(row, col)){
      removeBox(row, col);
    }else{
      addBox(row, col);
    }
  }

  void addBox(int row,int col){
    _pickedBox.add((row, col));
    notifyListeners();
  }

  void removeBox(int row,int col){
    _pickedBox.remove((row, col));
    notifyListeners();
  }

  void clearBox(){
    _pickedBox.clear();
    notifyListeners();
  }

  bool isBoxSelected(int row,int col){
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



  RegisterViewModel();

}