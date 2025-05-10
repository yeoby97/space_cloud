import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:space_cloud/main/warehouse/register/warehouse_register_view_model.dart';

class Layout extends StatelessWidget {
  const Layout({super.key});

  @override
  Widget build(BuildContext context) {
    RegisterViewModel viewModel = context.watch<RegisterViewModel>();
    double height = viewModel.row! * 70 + 3000;
    double width = (viewModel.col! >= 5 ? viewModel.col! : 5) * 70 + 1000;


    return WillPopScope(
      onWillPop: () async {
        viewModel.toggleLayout();
        return false;
      },
      child: Scaffold(
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            scaleEnabled: true,
            minScale: 0.2,
            maxScale: 4.0,
            constrained: false, // 중요: 크기를 자식에 맡김
            child: Container(
              padding: EdgeInsets.fromLTRB(270, 570, 680, 2250),
              width: width,
              height: height,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.blue,
                    width: 4.0,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ...List.generate(viewModel.row!, (r) {
                      return Row(
                        children: [
                          if (viewModel.col! < 5) SizedBox(width: 35.0*(5-viewModel.col!),),
                          ...List.generate(viewModel.col!, (c) {
                            return Padding(
                              padding: EdgeInsets.all(10),
                              child: GestureDetector(
                                onTap: () {viewModel.touchBox(r, c);},
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  color: viewModel.isBoxSelected(r, c) ? Colors.blue : Colors.grey,
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                    SizedBox(height: 10),
                    Text(
                      '남은 상자 수 : ${viewModel.count! - viewModel.pickedBox.length}',
                      style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}