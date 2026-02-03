import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:time_table/screens/login_screen.dart';
import 'package:time_table/utils/notification_service.dart';

import 'screens/splash_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/role_redirect_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "TimeTable App",
      initialRoute: "/splash",
      routes: {
        "/splash": (context) => const SplashScreen(),
        "/signup": (context) => const SignupScreen(),
        "/login": (context) => const LoginScreen(),
        "/redirect": (context) => const RoleRedirectScreen(),
      },
    );
  }
}
