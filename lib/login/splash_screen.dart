import 'package:flutter/material.dart';
import 'login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), //4초 애니메이션
    );

    //애니메이션 끝나면 login.dart 로 이동
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });

    _controller.forward(); //한 번만 실행
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
            //로고 and 퍼져나가는 원
            SizedBox(
              width: 350,
              height: 350,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  //첫 번째 원
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Container(
                        width: 161 + 180 * _controller.value,
                        height: 161 + 180 * _controller.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFA1C0FF)
                              .withOpacity(1 - _controller.value),
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
                        width: 161 + 180 * delayValue,
                        height: 161 + 180 * delayValue,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFA1C0FF)
                              .withOpacity(1 - delayValue),
                        ),
                      );
                    },
                  ),

                  //중앙 로고
                  Container(
                    width: 161,
                    height: 161,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFA1C0FF),
                    ),
                    child: Center(
                      child: Image.asset(
                        "assets/images/logo.png",
                        width: 161,
                        height: 161,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            //sosaw.png
            Image.asset(
              "assets/images/sosaw.png",
              width: 140,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
