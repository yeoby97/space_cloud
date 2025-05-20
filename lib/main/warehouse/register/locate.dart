import 'package:flutter/material.dart';
import 'package:space_cloud/main/warehouse/register/warehouse_register_view_model.dart';

class Locate extends StatefulWidget {
  const Locate({super.key});

  @override
  State<Locate> createState() => _LocateState();
}

class _LocateState extends State<Locate> {
  late final RegisterViewModel viewModel;

  @override
  void initState() {
    super.initState();

    viewModel = RegisterViewModel();
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(

    );
  }
}
