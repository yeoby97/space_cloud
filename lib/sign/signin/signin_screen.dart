import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:space_cloud/sign/signin/sigin_view_model.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider(
        create: (_) => SignInViewModel(),
        child: const _SignInBody(),
      ),
    );
  }
}

class _SignInBody extends StatelessWidget {
  const _SignInBody();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SignInViewModel>();

    return Center(
      child: viewModel.isLoading
          ? const CircularProgressIndicator()
          : ElevatedButton(
        onPressed: () => _handleSignIn(context, viewModel),
        child: const Text('Google 로그인'),
      ),
    );
  }

  Future<void> _handleSignIn(BuildContext context, SignInViewModel viewModel) async {
    final success = await viewModel.signInWithGoogle();
    if (context.mounted && success) {
      Navigator.pop(context, true);
    }
  }
}
