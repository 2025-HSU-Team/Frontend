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

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

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
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4E2FF),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //로고 + 애니메이션 파동
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
                            color: const Color(0xFFA1C0FF).withOpacity(0.3),
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

              //SO SAW
              const Text(
                "SO SAW",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3F3E3E),
                ),
              ),

              const SizedBox(height: 40),

              //아이디 입력
              Container(
                width: 300,
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "아이디를 입력해 주세요.",
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              //비밀번호
              Container(
                width: 300,
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _pwController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "비밀번호를 입력해 주세요.",
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              //로그인
              SizedBox(
                width: 300,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    //여기에 로그인 기능
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6497FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "로그인",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              //회원가입
              SizedBox(
                width: 300,
                height: 44,
                child: OutlinedButton(
                  onPressed: () {
                    // 여기에 회원가입 로직 
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6497FF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "회원가입",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6497FF),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              //게스트 계정
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WithoutScreen()),
                  );
                },
                child: const Text(
                  "게스트 계정으로 사용하기",
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
      ),
    );
  }
}
