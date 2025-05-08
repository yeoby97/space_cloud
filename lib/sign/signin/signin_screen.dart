import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:space_cloud/sign/signin/signin_view_model.dart';

import '../signup/signup_screen.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider(
        create: (_) => SignInViewModel(),
        child: _SignInBody(),
      ),
    );
  }
}

class _SignInBody extends StatelessWidget {

  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  _SignInBody();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SignInViewModel>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator(),)
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 이메일 입력 필드 컨트롤러 : emailController, 컨트롤러로 텍스트 추출 가능, 즉 컨트롤러가 텍스트입력 컨트롤러
          // TextFormField(
          //   controller: emailController,
          //   decoration: const InputDecoration(
          //     border: OutlineInputBorder(),
          //     labelText: '이메일',
          //   ),
          // ),
          // const SizedBox(height: 30),
          // // 비밀번호 입력 필드
          // TextField(
          //   controller: passwordController,
          //   decoration: const InputDecoration(
          //     border: OutlineInputBorder(),
          //     labelText: '비밀번호',
          //   ),
          // ),
          //
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.end,
          //   children: [
          //     TextButton(
          //       onPressed: () {
          //         // 회원가입 화면으로 이동
          //         Navigator.of(context).push(
          //           MaterialPageRoute(
          //               builder: (_) => SignupScreen()
          //           ),
          //         );
          //       },
          //       child: const Text('회원가입'),
          //     ),
          //     TextButton(
          //       onPressed: () {
          //         // 비밀번호 찾기 등의 동작
          //       },
          //       child: const Text('로그인'),
          //     ),
          //   ],
          // ),

          const SizedBox(height: 50),
          // 구글 로그인 버튼, 버튼 클릭 시 _handleSignIn 함수 실행 - SignInViewModel.signInWithGoogle()
          Center(
            child: ElevatedButton(
              onPressed: () => _handleGoogleSignIn(context, viewModel),
              child: const Text('Google 로그인'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context, SignInViewModel viewModel) async {
    final success = await viewModel.signInWithGoogle();
    if (context.mounted && success) {
      Navigator.pop(context, true);
    }
  }
}
