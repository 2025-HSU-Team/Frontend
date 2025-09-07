import 'package:flutter/material.dart';
import 'package:frontend/custom/add_sounds.dart';
import 'package:frontend/custom/before_login.dart';
import 'package:frontend/custom/basic_screen.dart';
import 'package:frontend/custom/delete_screen.dart';

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
      home: const DeleteScreen(), //실행 시 바로 BeforeLogin 보여줌
    );
  }
}
