import 'package:flutter/material.dart';

class BasicScreen extends StatelessWidget {
  const BasicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Column(
        children: [
          const SizedBox(height: 60),

          // 상단 로고만 표시
          Center(
            child: ClipOval(
              child: Image.asset(
                'assets/images/basic.png',
                width: 55,
                height: 55,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),

      //하단 재사용할 거 (성훈이 코드 받으면 여기에 넣을 예정)
      // bottomNavigationBar: BottomBar(
      //   currentIndex:0,
      //   onTap(index){
      //     //
      // }
      // ),
    );
  }
}
