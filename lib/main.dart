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
import 'main/warehouse/my_warehouse_view_model.dart';
import 'main/warehouse/register/blueprint/touch_counter.dart';

void main() async {
  WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _initializePermissions();

  final userVM = UserViewModel();
  if (FirebaseAuth.instance.currentUser != null) {
    await userVM.loadUser();
  }

  FlutterNativeSplash.remove();

  runApp(MyApp(userVM: userVM));
}

class MyApp extends StatelessWidget {
  final UserViewModel userVM;
  const MyApp({super.key, required this.userVM});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserViewModel>.value(value: userVM),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => MyLocationViewModel()),
        ChangeNotifierProvider(create: (_) => MyWarehouseViewModel()),
        ChangeNotifierProvider(create: (_) => TouchCounterNotifier()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(scaffoldBackgroundColor: Colors.white),
        home: const MainScreen(),
      ),
    );
  }
}

Future<void> _initializePermissions() async {
  final location = Location();
  if (kIsWeb) return;

  bool serviceEnabled = await location.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) return;
  }

  PermissionStatus permission = await location.hasPermission();
  if (permission == PermissionStatus.denied) {
    await location.requestPermission();
  }
}
