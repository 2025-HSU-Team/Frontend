import 'package:flutter/material.dart';
import '/custom/before_login.dart';
import 'login.dart';

class WithoutScreen extends StatefulWidget {
  const WithoutScreen({super.key});

  @override
  State<WithoutScreen> createState() => _WithoutScreenState();
}

class _WithoutScreenState extends State<WithoutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4E2FF),
      body: Column(
        children: [
          const SizedBox(height: 148),

          //상단 로고 and 파장
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                //첫 번째 원
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Container(
                      width: 100 + 60 * _controller.value,
                      height: 100 + 60 * _controller.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFA1C0FF).withOpacity(0.3),
                      ),
                    );
                  },
                ),

                //두 번째 원 (반 박자 늦게)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final delayValue = (_controller.value + 0.5) % 1.0;
                    return Container(
                      width: 100 + 60 * delayValue,
                      height: 100 + 60 * delayValue,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFA1C0FF).withOpacity(0.15),
                      ),
                    );
                  },
                ),

                //중앙 로고
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFA1C0FF).withOpacity(0.8),
                  ),
                  child: Center(
                    child: Image.asset(
                      "assets/images/logo.png",
                      width: 70,
                      height: 70,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          //sosaw 텍스트
          Image.asset(
            "assets/images/sosaw.png",
            width: 90,
            fit: BoxFit.contain,
          ),

          const SizedBox(height: 52),

          //안내 카드
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
                    "로그인 없이 서비스 이용하면\n내가 만든 소리를 위치에서\n사용할 수 없습니다!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  //괜찮아요 누르면 before_login으로 이동
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BeforeLogin(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6497FF),
                      minimumSize: const Size(210, 33),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: const Text(
                      "괜찮아요!",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 33),

          //'로그인 없이 이용하기' 누르면 withoutlogin으로 이동
          GestureDetector(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
                    (route) => false,
              );
            },
            child: const Text(
              "로그인 화면으로 돌아가기",
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                decoration: TextDecoration.underline,
                decorationThickness: 1.2,
                decorationColor: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
