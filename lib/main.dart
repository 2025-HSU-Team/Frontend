import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      appBar: AppBar(title:  Text(
        'Hello flutter',
        style: TextStyle(fontSize: 28),
      ),
        centerTitle: true, //가운데 정렬 하겠다라는 뜻
      ),
      body:SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16), //edgeInsets.all은 왼오위아래 사방에 대해서 적용
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Image.network("https://i.ibb.co/CwzHq4z/trans-logo-512.png",
                  width: 81,),
              ),
              TextField(decoration: InputDecoration(labelText: '이메일'),
              ),
              TextField(
                obscureText: true, //비밀번호 형식 쓸 때 보안 필요 시 사용
                decoration: InputDecoration(labelText: '비밀번호'),
              ),
              Container(
                width: double.infinity, //애뮬레이터 크기에 맞게 최대 크기만큼
                margin: const EdgeInsets.only(top: 16), // 위쪽에만 여백 16
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text('로그인'),
                ),
              )
            ],
          ),
        ),
      ),
    ),
    );
  }
}
