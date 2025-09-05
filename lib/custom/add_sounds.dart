import 'package:flutter/material.dart';

class AddSounds extends StatefulWidget {
  const AddSounds({super.key});

  @override
  State<AddSounds> createState() => _AddSoundsState();
}

class _AddSoundsState extends State<AddSounds> {
  final TextEditingController _controller = TextEditingController();
  bool _isNotEmpty = false; //입력 여부 상태 저장
  String _selectedColor = "blue"; //기본 색상 파란색

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _isNotEmpty = _controller.text.isNotEmpty; //입력되면 true
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4E2FF), //배경색
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 44),

              //로고
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

          //흰 박스
          Positioned(
            top: 137, //피그마 기준 맨 위에서 하얀박스까지 거리
            left: (MediaQuery.of(context).size.width - 328) / 2, //가운데 정렬
            child: Container(
              width: 328,
              height: 539,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),

              //흰 박스 안에 내용 추가
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "소리 추가하기",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    //입력 필드
                    TextField(
                      controller: _controller,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _isNotEmpty ? FontWeight.bold : FontWeight.normal, //입력된 글자
                        color: Colors.black,
                      ),
                      decoration: const InputDecoration(
                        hintText: "추가 할 소리명을 입력 해주세요.",
                        hintStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey,
                        ),
                        border: UnderlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    //추가 할 이모지 부분
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16)),
                              ),
                              builder: (context) {
                                return SizedBox(
                                  height: 200,
                                  child: const Center(
                                    child: Text("여기에 select_imoji.dart 연결예정",
                                        style: TextStyle(fontSize: 14)),
                                  ),
                                );
                              },
                            );
                          },
                          child: const Text(
                            "추가 할 이모지 >",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87, //검정87프로
                            ),
                          ),
                        ),

                        // 파동 색상 선택
                        Row(
                          children: [
                            const Text(
                              "파동 색상 선택",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54, //검정 54프로
                              ),
                            ),
                            const SizedBox(width: 6),

                            // 파랑 버튼
                            GestureDetector(
                              onTap: () => setState(() => _selectedColor = "blue"),
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Color(0xFFB9D0FF),
                                child: _selectedColor == "blue"
                                    ? const Icon(Icons.check,
                                    size: 19, color: Color(0xFF0054FF))
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 6),

                            // 초록 버튼
                            GestureDetector(
                              onTap: () => setState(() => _selectedColor = "green"),
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Color(0xFFCCFFA5),
                                child: _selectedColor == "green"
                                    ? const Icon(Icons.check,
                                    size: 14, color: Colors.green)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 6),

                            // 빨강 버튼
                            GestureDetector(
                              onTap: () => setState(() => _selectedColor = "red"),
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Color(0xFFFFD7D4),
                                child: _selectedColor == "red"
                                    ? const Icon(Icons.check,
                                    size: 14, color: Colors.red)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      //하단 재사용할 거 (성훈이 코드 받으면 여기에 넣을 예정)
      //bottomNavigationBar: BottomBar(
      //   currentIndex: 0,
      //   onTap(index) {
      //     //
      //   }
      // ),
    );
  }
}


