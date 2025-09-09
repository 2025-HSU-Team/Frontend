import 'package:flutter/material.dart';

// 앱에서 사용하는 화면들
import 'package:frontend/custom/add_sounds.dart';
import 'package:frontend/custom/before_login.dart';
import 'package:frontend/custom/basic_screen.dart';
import 'package:frontend/custom/delete_screen.dart';
import 'package:frontend/login/splash_screen.dart';
import 'package:frontend/login/login.dart';
import 'package:frontend/login/withoutlogin.dart';
// import 'pages/mainPage/mainPage.dart'; // 필요 시 사용

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Movie App',
      home: const SplashScreen(), // 실행 시 스플래시
      // routes나 onGenerateRoute가 필요하면 여기서 추가
    );
  }
}
