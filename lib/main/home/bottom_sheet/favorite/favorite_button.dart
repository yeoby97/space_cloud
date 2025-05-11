// TODO : 최적화 및 상태 최상단화

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/sign/signin/signin_screen.dart';
import '/data/warehouse.dart';
import '../../home_view_model.dart';

class FavoriteButton extends StatelessWidget {
  final Warehouse warehouse;

  const FavoriteButton({super.key, required this.warehouse});

  @override
  Widget build(BuildContext context) {
    final homeVM = context.watch<HomeViewModel>();
    final isFavorited = homeVM.isFavorite(warehouse.id);

    return IconButton(
      onPressed: () async {
        final navigator = Navigator.of(context);
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final homeViewModel = context.read<HomeViewModel>();

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          final result = await navigator.push(
            MaterialPageRoute(builder: (_) => const SignInScreen()),
          );
          if (result == null) {
            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('로그인 후 이용할 수 있습니다.')),
            );
            return;
          }
        }

        await homeViewModel.toggleFavorite(warehouse);
      },
      icon: Icon(
        isFavorited ? Icons.favorite : Icons.favorite_border,
        color: isFavorited ? Colors.red : Colors.grey,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      autofocus: false,
    );
  }
}
