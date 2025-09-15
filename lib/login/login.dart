import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'withoutlogin.dart';
import 'signup.dart'; // 회원가입 화면 이동
import '../custom/basic_screen.dart';


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

  String? _loginError; //로그인 에러 메시지 저장

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(); // 무한 반복
  }

  @override
  void dispose() {
    _controller.dispose();
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final url = Uri.parse("https://13.209.61.41.nip.io/api/users/signin");
    final body = {
      "id": _idController.text.trim(),
      "password": _pwController.text.trim(),
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["isSuccess"] == true) {
          //로그인 성공
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("로그인 성공!")),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BasicScreen()),
          );
        } else {

          //로그인 실패
          setState(() {
            _loginError = data["message"] ?? "로그인 실패";
          });
        }
      } else {
        setState(() {
          _loginError = "서버 오류: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _loginError = "네트워크 오류: $e";
      });
    }
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

              //아이디 pill + 입력
              Container(
                width: 300,
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6497FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "아이디",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6497FF),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _idController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "아이디를 입력해 주세요.",
                          hintStyle: TextStyle(
                              fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              //비밀번호 pill + 입력
              Container(
                width: 300,
                margin: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6497FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "비밀번호",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6497FF),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _pwController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "비밀번호를 입력해 주세요.",
                          hintStyle: TextStyle(
                              fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              //로그인 버튼
              SizedBox(
                width: 300,
                height: 44,
                child: ElevatedButton(
                  onPressed: _login,
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

              //회원가입 버튼
              SizedBox(
                width: 300,
                height: 44,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignupScreen()),
                    );
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
