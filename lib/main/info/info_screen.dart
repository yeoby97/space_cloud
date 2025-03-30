import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {

    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Container(
                padding: EdgeInsets.all(10),
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey.withAlpha(50),
                ),
                child: Row(
                  spacing: 20,
                  children: [
                    Icon(Icons.person, size: 50),
                    Column(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${user!.displayName}'),
                        Text('${user.email}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 0,horizontal: 20),
              child: Container(
                padding: EdgeInsets.all(10),
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.grey.withAlpha(50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${user.uid}"),
                    FloatingActionButton(
                      onPressed: (){},
                      backgroundColor: Colors.white,
                      child: Text('수정'),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Container(
                padding: EdgeInsets.all(10),
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey.withAlpha(50),
                ),
                child: Column(
                  spacing: 10,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.warehouse_outlined, size: 30),
                            Text('이용기록'),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.warehouse_outlined, size: 30),
                            Text('이용기록'),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.warehouse_outlined, size: 30),
                            Text('이용기록'),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.warehouse_outlined, size: 30),
                            Text('이용기록'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
