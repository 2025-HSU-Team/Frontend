import 'package:flutter/material.dart';
import 'withoutlogin.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(); //무한 반복
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //로고 and 파형 애니메이션
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [

                  //첫 번째 원
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Container(
                        width: 161 + 100 * _controller.value,
                        height: 161 + 100 * _controller.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFA1C0FF).withOpacity(0.3),//이걸로 투명도 조절 가능

                        ),
                      );
                    },
                  ),

                  //두 번째 원 (반박자 늦게)
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final delayValue = (_controller.value + 0.5) % 1.0;
                      return Container(
                        width: 161 + 100 * delayValue,
                        height: 161 + 100 * delayValue,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFA1C0FF).withOpacity(0.1),

                        ),
                      );
                    },
                  ),

                  //중앙 로고
                  Container(
                    width: 161,
                    height: 161,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFA1C0FF).withOpacity(0.8),
                    ),
                    child: Center(
                      child: Image.asset(
                        "assets/images/logo.png",
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            //sosaw 로고
            Image.asset(
              "assets/images/sosaw.png",
              width: 113,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 60),

            //카카오 로그인 버튼
            GestureDetector(
              onTap: () {
                //여기에 클릭 시 연결되는 기능 나중에 연결
              },
              child: Container(
                width: 300,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE102),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/images/kakao.png",
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "카카오톡으로 로그인하기",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 로그인 없이 이용하기
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WithoutScreen()),
                );
              },
              child: const Text(
                "로그인 없이 서비스 이용하기 >",
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
      ),
    );
  }
}
