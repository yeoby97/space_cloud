// TODO : 최적화 및 상태 최상단화

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:space_cloud/main/warehouse/register/warehouse_register_view_model.dart';

import '../../../data/warehouse.dart';
import '../../home/search/search_screen.dart';
import 'layout.dart';

class WarehouseRegisterScreen extends StatefulWidget {
  const WarehouseRegisterScreen({super.key});

  @override
  State<WarehouseRegisterScreen> createState() => _WarehouseRegisterScreenState();
}

class _WarehouseRegisterScreenState extends State<WarehouseRegisterScreen> {

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterViewModel(),
      child: Body(),
    );
  }

  // void upload() async {
  //   final price = int.tryParse(priceController.text.replaceAll(',', ''));
  //   final count = int.tryParse(numberController.text);
  //   final rows = int.tryParse(rowController.text);
  //   final columns = int.tryParse(colController.text);
  //
  //   if (pickedImages == null || pickedImages!.isEmpty ||
  //       address == null ||
  //       location == null ||
  //       detailAddressController.text.trim().isEmpty ||
  //       price == null || price <= 0 ||
  //       count == null || count <= 0 ||
  //       rows == null || rows <= 0 ||
  //       columns == null || columns <= 0 ||
  //       rows * columns != count) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("모든 정보를 올바르게 입력해주세요.")),
  //     );
  //     return;
  //   }
  //
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("로그인이 필요합니다.")),
  //     );
  //     return;
  //   }
  //
  //   setState(() => isLoading = true);
  //
  //   try {
  //     final folderName = '${address!}_${detailAddressController.text.trim()}';
  //     final storageRef = FirebaseStorage.instance.ref().child('warehouses/$folderName');
  //     List<String> imageUrls = [];
  //
  //     for (int i = 0; i < pickedImages!.length; i++) {
  //       final file = File(pickedImages![i].path);
  //       final uploadRef = storageRef.child('${i + 1}.jpeg');
  //       await uploadRef.putFile(file);
  //       final downloadUrl = await uploadRef.getDownloadURL();
  //       imageUrls.add(downloadUrl);
  //     }
  //
  //     // 창고 정보 생성
  //     final warehouse = Warehouse(
  //       address: address!,
  //       detailAddress: detailAddressController.text.trim(),
  //       lat: location!.latitude,
  //       lng: location!.longitude,
  //       images: imageUrls,
  //       price: price,
  //       count: count,
  //       createdAt: DateTime.now(),
  //       ownerId: user.uid,
  //       layout: {
  //         'rows': rows,
  //         'columns': columns,
  //       },
  //     );
  //
  //     // 창고 문서 저장
  //     final docRef = await FirebaseFirestore.instance
  //         .collection('warehouse')
  //         .add(warehouse.toMap());
  //
  //     // 공간 정보 저장
  //     for (int r = 0; r < rows; r++) {
  //       for (int c = 0; c < columns; c++) {
  //         final spaceId = '${String.fromCharCode(65 + r)}${c + 1}';
  //         await docRef.collection('spaces').doc(spaceId).set({
  //           'spaceId': spaceId,
  //         });
  //       }
  //     }
  //
  //     if (!mounted) return;
  //
  //     Navigator.of(context).pop();
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("등록 실패: $e")),
  //     );
  //   } finally {
  //     if (mounted) setState(() => isLoading = false);
  //   }
  // }
}

class Body extends StatelessWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context) {
    RegisterViewModel viewModel = context.watch<RegisterViewModel>();

    return viewModel.isLayout ? Layout() : WarehouseRegisterBody();
  }
}


class _PhotoButton extends StatelessWidget {
  final VoidCallback onTap;
  final int pickedCount;

  const _PhotoButton({
    super.key,
    required this.onTap,
    required this.pickedCount,
  });

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 28),
            const SizedBox(height: 4),
            Text('$pickedCount/10', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class WarehouseRegisterBody extends StatelessWidget {
  const WarehouseRegisterBody({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RegisterViewModel>();
    // 가격 포맷
    final _priceFormat = NumberFormat("#,##0", "ko_KR");

    return Scaffold(
      // stack - 입력 위젯과 로딩위젯 중첩 - 나중에 stack 안쓰는 방향으로 수정 가능
      body: Stack(
        children: [
          SafeArea(
            // 벽에 안붙게 패딩
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              // 스크롤 - 타자판 올라올 때 화면 overflow 방지
              child: SingleChildScrollView(
                // 본 화면 위젯
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 윗 패딩 역할
                    const SizedBox(height: 30),
                    // 사진 관련 위젯
                    Row(
                      children: [
                        // 사진 업로드 버튼
                        _PhotoButton(
                          // 탭하면 갤러리 이동
                          onTap: viewModel.pickImage,
                          // 현제 업로드된 사진갯수
                          pickedCount: viewModel.images.length,
                        ),
                        _PhotoList(
                          // 사진 리스트
                          pickedImages: viewModel.images,
                        ),
                      ],
                    ),
                    // 간격
                    const SizedBox(height: 16),
                    // 이벤트발생기
                    GestureDetector(
                      // 주소 선택
                      onTap: () => viewModel.selectLocation(context),
                      // 주소 선택시 주소 표시
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          viewModel.address ?? '주소',
                          style: TextStyle(
                            fontSize: 20,
                            color: viewModel.address == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    // 간격
                    const SizedBox(height: 12),
                    // 텍스트 입력 필드
                    _BuildTextField(hint: '상세 주소'),
                    // ..
                    const SizedBox(height: 12),
                    // ..
                    _BuildNumberField(hint: '월 대여료',unit:  '₩',formatter: _priceFormat,controller: viewModel.priceController),
                    // ..
                    const SizedBox(height: 12),
                    // ..
                    _BuildNumberField(hint: '창고 갯수',unit: '개',controller: viewModel.countController),
                    // ..
                    const SizedBox(height: 12),

                    // ✅ 행/열 입력 필드
                    Row(
                      children:[
                        // Expanded - 화면을 가능한 최대한으로 맞추게 해줌
                        // 현제는 sizedbox 2개를 제외한 공간을 2개로 분할해 차지
                        // Expanded 사용 안하면 오류 - textfield는 기본적으로 가로화면 전체 차지해서 오버플로우
                        Expanded(child: _BuildNumberField(hint: '행',unit:  '',controller: viewModel.rowController)),
                        const SizedBox(width: 12),
                        Expanded(child: _BuildNumberField(hint: '열',unit:  '',controller: viewModel.colController)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ✅ 미리보기 UI
                    //
                    if (viewModel.row != 0 && viewModel.col != 0)
                      _BuildMatrixPreview(),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FloatingActionButton.extended(
                        onPressed: ()=>(),
                        label: const Text("등록", style: TextStyle(fontSize: 16)),
                        icon: const Icon(Icons.check),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (viewModel.isLoading)
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
}


class _PhotoList extends StatelessWidget {
  final List<XFile>? pickedImages;

  const _PhotoList({
    super.key,
    required this.pickedImages,
  });

  @override
  Widget build(BuildContext context) {

    final viewModel = context.watch<RegisterViewModel>();

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
                      onTap: () => viewModel.deletePhoto(index),
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

class _BuildTextField extends StatelessWidget {
  final hint;

  const _BuildTextField({super.key, required this.hint,});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    final viewModel = context.watch<RegisterViewModel>();

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
        onChanged: (detailAddress) {viewModel.detailAddress = detailAddress;},
      ),
    );
  }
}


class _BuildMatrixPreview extends StatelessWidget {

  const _BuildMatrixPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RegisterViewModel>();

    if (viewModel.row == null || viewModel.col == null || viewModel.count == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("배치 설정하기", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ElevatedButton(
            onPressed: () {
              viewModel.toggleLayout();
            },
            child: const Text("배치 설정하기", style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

class _BuildNumberField extends StatelessWidget {
  final String hint;
  final String unit;
  final NumberFormat? formatter;
  final controller;
  _BuildNumberField({super.key, required this.hint, required this.unit,this.formatter,required this.controller});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RegisterViewModel>();

    final focusMap = {
      '행': viewModel.rowFocusNode,
      '열': viewModel.colFocusNode,
      '창고 갯수': viewModel.countFocusNode,
    };

    setController(viewModel,controller,hint);
    final formatter = this.formatter;
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
              focusNode: focusMap[hint],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                FilteringTextInputFormatter.digitsOnly,
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final text = newValue.text.replaceAll(',', '');
                  int? value = int.tryParse(text);
                  changeNumber(viewModel,hint,value);
                  if (text.isEmpty) return newValue;
                  final formatted = formatter?.format(value) ?? value.toString();
                  return TextEditingValue(
                    text: formatted,
                  );
                })
              ],
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
  void changeNumber(RegisterViewModel viewModel,String hint,int? num){
    switch(hint){
      case '행':
        viewModel.rowChange(num);
        break;
      case '열':
        viewModel.colChange(num);
        break;
      case '월 대여료':
        viewModel.price = num;
        break;
      case '창고 갯수':
        viewModel.countChange(num);
        break;
      default:
    }
  }
  void setController(RegisterViewModel viewModel,TextEditingController controller,String hint){
    switch(hint){
      case '행':
        controller.text = viewModel.row?.toString() ?? '';
        break;
      case '열':
        controller.text = viewModel.col?.toString() ?? '';
        break;
      case '월 대여료':
        controller.text = viewModel.price?.toString() ?? '';
        break;
      case '창고 갯수':
        controller.text = viewModel.count?.toString() ?? '';
        break;
      default:
    }
  }
}

