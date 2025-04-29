// TODO : 최적화 및 상태 최상단화

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PhoneNumberManager {
  static Future<void> showPhoneNumberEditDialog(
      BuildContext context,
      String initialPhone,
      void Function(String) onUpdated,
      ) async {
    final controller = TextEditingController(text: formatPhoneNumber(initialPhone));
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('전화번호 수정'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: '010-1234-5678'),
            validator: (value) {
              final digits = _onlyDigits(value);
              if (digits.length < 10 || digits.length > 11) {
                return '올바른 전화번호를 입력하세요';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final cleaned = _onlyDigits(controller.text);
                await _updatePhoneNumber(cleaned);
                onUpdated(cleaned);
                Navigator.pop(context);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  static Future<void> _updatePhoneNumber(String phone) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'phoneNumber': phone});
  }

  static String _onlyDigits(String? value) =>
      value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';

  static String formatPhoneNumber(String phone) {
    if (phone.length == 11) {
      return '${phone.substring(0, 3)}-${phone.substring(3, 7)}-${phone.substring(7)}';
    } else if (phone.length == 10) {
      return '${phone.substring(0, 3)}-${phone.substring(3, 6)}-${phone.substring(6)}';
    }
    return phone;
  }
}
