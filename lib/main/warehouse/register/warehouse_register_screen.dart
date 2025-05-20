import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:space_cloud/main/warehouse/register/warehouse_register_view_model.dart';

import 'blueprint/blueprint_editor_screen.dart';
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
      child: const Body(),
    );
  }
}

class Body extends StatelessWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RegisterViewModel>();
    if (viewModel.isDraw) {
      return const BlueprintEditorScreen();
    } else if (viewModel.isLayout) {
      return const Layout();
    } else {
      return const WarehouseRegisterBody();
    }
  }
}

class _PhotoButton extends StatelessWidget {
  final VoidCallback onTap;
  final int pickedCount;

  const _PhotoButton({required this.onTap, required this.pickedCount});

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
    final NumberFormat priceFormat = NumberFormat("#,##0", "ko_KR");

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        _PhotoButton(
                          onTap: viewModel.pickImage,
                          pickedCount: viewModel.images.length,
                        ),
                        _PhotoList(pickedImages: viewModel.images),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => viewModel.selectLocation(context),
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
                    const SizedBox(height: 12),
                    const _BuildTextField(hint: '상세 주소'),
                    const SizedBox(height: 12),
                    _BuildNumberField(hint: '월 대여료', unit: '₩', formatter: priceFormat, controller: viewModel.priceController),
                    const SizedBox(height: 12),
                    _BuildNumberField(hint: '창고 갯수', unit: '개', controller: viewModel.countController),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FloatingActionButton.extended(
                        onPressed: () {
                          viewModel.drawChange(true);
                        },
                        label: const Text("건물 도면 그리기", style: TextStyle(fontSize: 16)),
                        icon: const Icon(Icons.check),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _BuildNumberField(hint: '행', unit: '', controller: viewModel.rowController)),
                        const SizedBox(width: 12),
                        Expanded(child: _BuildNumberField(hint: '열', unit: '', controller: viewModel.colController)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (viewModel.row != 0 && viewModel.col != 0) const _BuildMatrixPreview(),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FloatingActionButton.extended(
                        onPressed: () => viewModel.upload(context),
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
              color: Colors.black.withAlpha(128),
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

  const _PhotoList({required this.pickedImages});

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
                        decoration: const BoxDecoration(
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
  final String hint;

  const _BuildTextField({required this.hint});

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
        onChanged: (detailAddress) {
          viewModel.detailAddress = detailAddress;
        },
      ),
    );
  }
}

class _BuildMatrixPreview extends StatelessWidget {
  const _BuildMatrixPreview();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RegisterViewModel>();

    if (viewModel.row == null || viewModel.col == null || viewModel.count == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("배치 설정하기", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          '남은 상자 수 : ${viewModel.count! - viewModel.pickedBox.length}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(viewModel.row!, (r) {
                return Row(
                  children: [
                    if (viewModel.col! < 5) SizedBox(width: 35.0 * (5 - viewModel.col!)),
                    ...List.generate(viewModel.col!, (c) {
                      return Padding(
                        padding: const EdgeInsets.all(5),
                        child: GestureDetector(
                          onTap: () => viewModel.touchBox(r, c),
                          child: Container(
                            width: 30,
                            height: 30,
                            color: viewModel.isBoxSelected(r, c) ? Colors.blue : Colors.grey,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ),
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
  final TextEditingController controller;

  const _BuildNumberField({required this.hint, required this.unit, this.formatter, required this.controller});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RegisterViewModel>();

    final focusMap = {
      '행': viewModel.rowFocusNode,
      '열': viewModel.colFocusNode,
      '창고 갯수': viewModel.countFocusNode,
    };

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
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final text = newValue.text.replaceAll(',', '');
                  int? value = int.tryParse(text);
                  _changeNumber(viewModel, hint, value);
                  if (text.isEmpty) return newValue;
                  final formatted = formatter?.format(value) ?? value.toString();
                  return TextEditingValue(text: formatted);
                }),
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

  void _changeNumber(RegisterViewModel viewModel, String hint, int? num) {
    switch (hint) {
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
}
