import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/custom/add_sounds.dart';
import 'package:frontend/custom/before_login.dart';
import 'package:frontend/custom/basic_screen.dart';
import 'package:frontend/custom/delete_screen.dart';
import 'package:frontend/login/splash_screen.dart';
import 'package:frontend/login/login.dart';
import 'package:frontend/login/signup.dart';
import 'package:frontend/login/withoutlogin.dart';
import 'pages/mainPage/mainPage.dart';
import 'package:frontend/shared_components/bottom_navigation.dart';
import 'package:frontend/alarm/alarm_set.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Movie App',
      home: const LoginScreen(),
    );
  }
}
