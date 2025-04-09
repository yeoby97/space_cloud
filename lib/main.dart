import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:space_cloud/main/main_screen.dart';
import 'firebase/firebase_options.dart';
import 'main/home/home_view_model.dart';
import 'main/home/my_location/my_location_view_model.dart';

void main() async {
  WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint("Firebase 초기화 실패: $e");
    // TODO: 에러 UI 보여주기
  }

  await _initializePermissions();

  FlutterNativeSplash.remove();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MyLocationViewModel(),
          lazy: false,
        ),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}

Future<void> _initializePermissions() async {
  final location = Location();

  bool serviceEnabled = await location.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) {
      debugPrint("위치 서비스 사용 안됨");
      return;
    }
  }

  PermissionStatus permission = await location.hasPermission();
  if (permission == PermissionStatus.denied) {
    permission = await location.requestPermission();
    if (permission != PermissionStatus.granted) {
      debugPrint("위치 권한 거부됨");
      return;
    }
  }

  if (permission == PermissionStatus.deniedForever) {
    debugPrint("위치 권한 완전 거부됨 - 설정에서 허용 필요");
    return;
  }
}