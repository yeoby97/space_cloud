import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:space_cloud/main/main_screen.dart';
import 'package:space_cloud/main/home/home_view_model.dart';
import 'package:space_cloud/main/home/my_location/my_location_view_model.dart';
import 'data/user_view_model.dart';
import 'firebase/firebase_options.dart';

void main() async {

  // WidgetsBinding - 우선적으로 위젯을 flutter에 렌더링하기 위해 필요한 객체
  // 렌더링하는 이유는 파이어베이스 초기화를 하기 위해 렌더링이 필요하기 때문
  // 원래는 runapp() 내부에서 초기화
  WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();

  // 스플래쉬 화면 유지 - 파이어베이스 초기화, 위치 권한 등을 완료하기 전까지 유지
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // 파이어베이스 초기화 - 파이어베이스 사용시 필수
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 초기 위치 권한 설정
  await _initializePermissions();

  // userVM - 유저 정보를 담는 뷰모델
  final userVM = UserViewModel();
  if (FirebaseAuth.instance.currentUser != null) {
    await userVM.loadUser();
  }

  FlutterNativeSplash.remove();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserViewModel>.value(value: userVM),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => MyLocationViewModel()),
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
  if(!kIsWeb){
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
    }
  }
}
