import 'package:flutter/material.dart';

class SignupScreen extends StatelessWidget {

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordCheckController = TextEditingController();

  SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 100),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '이름',
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '이메일',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ElevatedButton(
                  //   onPressed: () {
                  //     // 회원가입 동작
                  //     // 이메일과 비밀번호를 사용하여 회원가입 처리
                  //   },
                  //   child: const Text('인증'),
                  // ),
                ],
              ),
              const SizedBox(height: 30),
              // 비밀번호 입력 필드
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '비밀번호',
                ),
              ),
              const SizedBox(height: 30),
              // 비밀번호 입력 필드
              TextField(
                controller: passwordCheckController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '비밀번호 확인',
                ),
              ),
              const SizedBox(height: 30),
              // 비밀번호 입력 필드
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: passwordCheckController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '휴대폰 번호',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ElevatedButton(
                  //   onPressed: () {
                  //     // 회원가입 동작
                  //     // 이메일과 비밀번호를 사용하여 회원가입 처리
                  //   },
                  //   child: const Text('인증'),
                  // ),
                ],
              ),
              const SizedBox(height: 50),
              // 회원가입 버튼
              ElevatedButton(
                onPressed: () {
                  // 회원가입 동작
                  // 이메일과 비밀번호를 사용하여 회원가입 처리
                },
                child: const Text('확인'),
              ),
            ],
          ),
        ),
      ),
    );
  }


}
