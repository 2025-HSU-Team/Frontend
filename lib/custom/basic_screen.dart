import 'package:flutter/material.dart';

class BasicScreen extends StatelessWidget {
  const BasicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4E2FF), // 배경색
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 44), // 상단 여백 (로고 위치)

              // 로고
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

          // 쓰레기통 (오른쪽 상단 고정)
          Positioned(
            top: 90,
            right: 21,
            child: Image.asset(
              'assets/images/trashcan.png',
              width: 50,
              height: 45,
              fit: BoxFit.contain,
            ),
          ),

          //쓰레기통 밑 흰 박스
          Positioned(
            top: 137,//피그마 기준 맨 위에서 하얀박스까지
            left: (MediaQuery.of(context).size.width - 328) / 2, //가운데  정렬 코드
            child: Container(
              width: 328,
              height: 539,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),

              ),

              //흰 박스 안에 추가하는 부분
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "기본음",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const Divider(color: Colors.black),

                    //기본음 9개
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 3,
                        mainAxisSpacing: 28,
                        crossAxisSpacing: 17,
                        padding: EdgeInsets.zero, //divider랑 간격 없게 하는법
                        children: const[
                          SoundBox(
                            image: 'assets/images/emergency.png',
                            label: '비상 경보음',
                            color:Colors.red,
                          ),

                          SoundBox(
                            image: 'assets/images/carsound.png',
                            label: '자동차 경적 소리',
                            color:Colors.red,
                          ),

                          SoundBox(
                            image: 'assets/images/fire.png',
                            label: '화재 경보 소리',
                            color: Colors.red,
                          ),
                          SoundBox(
                            image: 'assets/images/phonecall.png',
                            label: '전화 벨소리',
                            color: Colors.green,
                          ),
                          SoundBox(
                            image: 'assets/images/door.png',
                            label: '문 여닫는 소리',
                            color: Colors.green,
                          ),
                          SoundBox(
                            image: 'assets/images/bell.png',
                            label: '초인종 소리',
                            color: Colors.green,
                          ),
                          SoundBox(
                            image: 'assets/images/dog.png',
                            label: '개 짖는 소리',
                            color: Colors.blue,
                          ),
                          SoundBox(
                            image: 'assets/images/cat.png',
                            label: '고양이 우는 소리',
                            color: Colors.blue,
                          ),
                          SoundBox(
                            image: 'assets/images/babycry.png',
                            label: '아기 우는 소리',
                            color: Colors.blue,
                          ),


                        ],
                      ),
                    ),


                    const Text(
                      "커스텀",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),


                    const Divider(color: Colors.black),

                    // 커스텀 사운드 그리드
                    SizedBox(
                      height: 100, // 버튼 한 줄 높이만큼
                      child: GridView.count(
                        crossAxisCount: 3,
                        mainAxisSpacing: 28,
                        crossAxisSpacing: 17,
                        padding: EdgeInsets.zero,
                        children: const [
                          AddSoundBox(), // ✅ 처음엔 하나만
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            ),
          ),
        ],
      ),

      // 하단 재사용할 거 (성훈이 코드 받으면 여기에 넣을 예정)
      // bottomNavigationBar: BottomBar(
      //   currentIndex:0,
      //   onTap(index){
      //     //
      // }
      // ),
    );
  }
}


//soundbox 부분
class SoundBox extends StatelessWidget {
  final String image;
  final String label;
  final Color color;

  const SoundBox({
    super.key,
    required this.image,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, //높이를 내용물 기준으로
      children: [
        //사진 들어있는 버튼 박스
        Container(
          width: 80,
          height: 62,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Image.asset(image, width: 30, height: 30),
          ),
        ),
        const SizedBox(height: 4), //버튼과 글씨 간격
        //버튼 밑 텍스트
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// 소리 추가 버튼
class AddSoundBox extends StatelessWidget {
  const AddSoundBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 62,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.add, size: 32, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "소리 추가하기",
          style: TextStyle(
            fontSize: 10,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
