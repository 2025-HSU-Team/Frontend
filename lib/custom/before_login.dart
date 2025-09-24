import 'package:flutter/material.dart';
import 'package:frontend/config/app_config.dart';
import 'package:frontend/login/login.dart';
import 'package:frontend/shared_components/bottom_navigation.dart';

class BeforeLogin extends StatelessWidget {
  final int selectedTabIndex;
  final Function(int)? onTabChanged;

  const BeforeLogin({super.key, this.selectedTabIndex = 1, this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4E2FF),
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

          const SizedBox(height: 158),

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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
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

      bottomNavigationBar: BottomNavigation(
        selectedTabIndex: selectedTabIndex,
        onTabChanged: onTabChanged ?? (index) {},
      ),
    );
  }
}
