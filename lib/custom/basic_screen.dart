import 'package:flutter/material.dart';

class BasicScreen extends StatelessWidget {
  const BasicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4E2FF),
      body: Stack(
        children: [
          // 상단 로고 (가운데 정렬)
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 44),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/basic.png',
                  width: 55,
                  height: 55,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // 쓰레기통 (오른쪽 상단)
          Positioned(
            top: 91,
            right: 21,
            child: Image.asset(
              'assets/images/trashcan.png',
              width: 40,
              height: 41,
              fit: BoxFit.contain,
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
