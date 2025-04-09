import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:space_cloud/sign/signin/sigin_view_model.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignInViewModel(),
      child: const _SignInBody(),
    );
  }
}

class _SignInBody extends StatelessWidget {
  const _SignInBody();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SignInViewModel>();

    return Scaffold(
      body: Center(
        child: viewModel.isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
          onPressed: () async {
            final success = await viewModel.signInWithGoogle();
            if (success && context.mounted) Navigator.pop(context, true);
          },
          child: const Text('Google 로그인'),
        ),
      ),
    );
  }
}
