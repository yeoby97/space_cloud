import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UsageHistoryScreen extends StatelessWidget {
  User? user = FirebaseAuth.instance.currentUser;

  UsageHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

    );
  }
}
