import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:space_cloud/main/main_screen.dart';
import 'package:space_cloud/main/home/home_view_model.dart';
import 'package:space_cloud/main/home/my_location/my_location_view_model.dart';
import 'data/user_view_model.dart';
import 'firebase/firebase_options.dart';

void main() async {
  WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await _initializeApp();

  FlutterNativeSplash.remove();

  runApp(const MyApp());
}

Future<void> _initializeApp() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FlutterNaverMap().init(
    clientId: 'lo0sa9igjt',
    onAuthFailed: (ex) => switch (ex) {
      NQuotaExceededException(:final message) =>
          print("Naver Map 사용량 초과: $message"),
      NUnauthorizedClientException() ||
      NClientUnspecifiedException() ||
      NAnotherAuthFailedException() =>
          print("Naver Map 인증 실패: $ex"),
    },
  );

  await _initializeLocationPermission();
}

Future<void> _initializeLocationPermission() async {
  final location = Location();

  bool serviceEnabled = await location.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) {
      debugPrint('위치 서비스가 비활성화되어 있습니다.');
      return;
    }
  }

  PermissionStatus permission = await location.hasPermission();
  if (permission == PermissionStatus.denied) {
    permission = await location.requestPermission();
    if (permission != PermissionStatus.granted) {
      debugPrint('위치 권한이 거부되었습니다.');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserViewModel()..loadIfSignedIn()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => MyLocationViewModel()),
      ],
      child: MaterialApp(
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const MainScreen(),
      ),
    );
  }
}

extension on UserViewModel {
  Future<void> loadIfSignedIn() async {
    if (FirebaseAuth.instance.currentUser != null) {
      await loadUser();
    }
  }
}
