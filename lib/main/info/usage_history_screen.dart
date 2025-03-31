import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UsageHistoryScreen extends StatefulWidget {

  UsageHistoryScreen({super.key});

  @override
  State<UsageHistoryScreen> createState() => _UsageHistoryScreenState();
}

class _UsageHistoryScreenState extends State<UsageHistoryScreen> {
  User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(

    );
  }
}
