import 'package:firebase_auth/firebase_auth.dart';
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
    final isLoading = context.select<SignInViewModel, bool>((vm) => vm.isLoading);

    return Center(
      child: isLoading
          ? const CircularProgressIndicator()
          : ElevatedButton(
        onPressed: () => _handleSignIn(context),
        child: const Text('Google 로그인'),
      ),
    );
  }

  Future<void> _handleSignIn(BuildContext context) async {
    final navigator = Navigator.of(context);
    final viewModel = context.read<SignInViewModel>();

    final success = await viewModel.signInWithGoogle(context);

    if (success) {
      await FirebaseAuth.instance.authStateChanges().firstWhere((user) => user != null);
      if (context.mounted) {
        navigator.pop(true);
      }
    }
  }
}
