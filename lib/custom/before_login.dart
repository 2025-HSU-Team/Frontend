import 'package:flutter/material.dart';
import 'package:frontend/config/app_config.dart';

class BeforeLogin extends StatelessWidget {
  const BeforeLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Column(
        children: [
          const SizedBox(height: 60),

          //상단 로고
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

          const SizedBox(height: 40),

          //로그인 안내 카드
          Center(
            child: Container(
              width: 328,
              height: 182,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                shadows: [
                  BoxShadow(
                    color: const Color(0x146497FF),
                    blurRadius: 8,
                    offset: const Offset(0, 8),
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "로그인 후\n사용 가능한 기능입니다.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.mainColor,
                      minimumSize: const Size(120, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "로그인 하기",
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ],
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
