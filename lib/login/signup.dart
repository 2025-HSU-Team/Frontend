import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; //http 패키지
import 'dart:convert';
import 'login.dart';
import 'withoutlogin.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

  String? _idError;
  String? _pwError;
  String? _idCheckMessage; //아이디 중복 확인
  Color _idCheckColor = Colors.blue;

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
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _idError = null;
      _pwError = null;

      if (_idController.text.trim().isEmpty) {
        _idError = "아이디를 입력해 주세요.";
      } else if (_idController.text.length < 4 ||
          _idController.text.length > 12) {
        _idError = "영문 소문자와 숫자의 조합으로 4~12자 이내로 입력해 주세요.";
      }

      if (_pwController.text.trim().isEmpty) {
        _pwError = "비밀번호를 입력해 주세요.";
      } else if (_pwController.text.length < 4 ||
          _pwController.text.length > 12) {
        _pwError = "영문 소문자와 숫자의 조합으로 4~12자 이내로 입력해 주세요.";
      }
    });
  }

  //아이디 중복 확인 API
  Future<void> _checkDuplicateId() async {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      setState(() {
        _idCheckMessage = "아이디를 입력해 주세요.";
        _idCheckColor = Colors.red;
      });
      return;
    }

    final url = Uri.parse("https://13.209.61.41.nip.io/api/users/signup/checkId?id=$id");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isDuplicated = data["data"] ?? true;

        setState(() {
          if (isDuplicated) {
            _idCheckMessage = "해당 사용자가 이미 존재합니다.";
            _idCheckColor = Colors.red;
          } else {
            _idCheckMessage = "사용 가능한 아이디입니다.";
            _idCheckColor = Colors.blue;
          }
        });
      } else {
        setState(() {
          _idCheckMessage = "서버 오류: ${response.statusCode}";
          _idCheckColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        _idCheckMessage = "네트워크 오류: $e";
        _idCheckColor = Colors.red;
      });
    }
  }

  //회원가입 API 요청 함수
  Future<void> _signup() async {
    final url = Uri.parse("https://13.209.61.41.nip.io/api/users/signup");

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

      final data = jsonDecode(response.body);

      //성공 조건을 statusCode == 201 또는 isSuccess == true 로 체크(201이 먼 오륜지 몰라서 201도 처리하도록)
      if (response.statusCode == 201 && data["isSuccess"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("가입이 완료되었습니다.")),
        );

        Future.delayed(const Duration(seconds: 1, milliseconds: 500), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("회원가입 실패: ${data["message"] ?? response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("에러 발생: $e")),
      );
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
              //로고 애니메이션
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

              const SizedBox(height: 16),

              //SO SAW
              Image.asset("assets/images/sosaw.png",
                  width: 113, fit: BoxFit.contain),

              const SizedBox(height: 20),

              //회원가입
              Row(
                children: [
                  const Expanded(
                    child: Divider(
                      color: Color(0xFF6497FF),
                      thickness: 1,
                      endIndent: 0,
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6497FF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "회원가입",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6497FF),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(
                      color: Color(0xFF6497FF),
                      thickness: 1,
                      indent: 0,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              //아이디 입력
              Container(
                width: 210,
                margin: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //파란 '아이디'
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
                          fontSize: 10,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF6497FF),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    //입력 박스
                    SizedBox(
                      height: 27,
                      child: TextField(
                        controller: _idController,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: "아이디를 입력해 주세요.",
                          hintStyle: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: ElevatedButton(
                              onPressed: _checkDuplicateId,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD9D9D9),
                                minimumSize: const Size(54, 17),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 0),
                                tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              child: const Text(
                                "중복확인",
                                style: TextStyle(fontSize: 10, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    //중복 확인 결과 메시지 표시
                    if (_idCheckMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          _idCheckMessage!,
                          style: TextStyle(fontSize: 11, color: _idCheckColor),
                        ),
                      ),
                  ],
                ),
              ),

              //비밀번호 입력
              Container(
                width: 210,
                margin: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //파란 '비밀번호'
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
                          fontSize: 10,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF6497FF),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    SizedBox(
                      height: 27,
                      child: TextField(
                        controller: _pwController,
                        obscureText: true,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: "비밀번호를 입력해 주세요.",
                          hintStyle: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              //가입하기
              SizedBox(
                width: 210,
                height: 33,
                child: ElevatedButton(
                  onPressed: _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD9D9D9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    "가입하기",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              //게스트
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
