import 'package:flutter/material.dart';

class AddSounds extends StatefulWidget {
  const AddSounds({super.key});

  @override
  State<AddSounds> createState() => _AddSoundsState();
}

class _AddSoundsState extends State<AddSounds> {
  final TextEditingController _controller = TextEditingController();
  bool _isNotEmpty = false; //입력 여부 상태 저장

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
                    )

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
