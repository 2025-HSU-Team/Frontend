import 'package:flutter/material.dart';
import 'add_sounds.dart';
import '../shared_components/bottom_navigation.dart';

class BasicScreen extends StatefulWidget {
  const BasicScreen({super.key});

  @override
  State<BasicScreen> createState() => _BasicScreenState();
}

class _BasicScreenState extends State<BasicScreen> {//상태 클래스 생성
  final ScrollController _scrollController=ScrollController(); //스크롤바를 위한

  //커스텀 소리 리스트
  List<Map<String, dynamic>> customSounds = [];


  @override
  Widget build(BuildContext context) {
    final ScrollController _scrollController = ScrollController(); //스크롤바를 위한 선언
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

          //쓰레기통 (오른쪽 상단 고정)
          Positioned(
            top: 89,
            right: 21,
            child: Image.asset(
              'assets/images/trashcan.png',
              width: 50,
              height: 45,
              fit: BoxFit.contain,
            ),
          ),

          //수정하기
          Positioned(
            top: 89,
            right: 70,
            child: Image.asset(
              'assets/images/fix.png',
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
              height: 580,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),

              ),

              //흰 박스 안에 추가하는 부분
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Scrollbar(
                  controller: _scrollController, //스크롤바 컨트롤러
                  thumbVisibility: true, //스크롤바 항상 보이게
                  child: SingleChildScrollView(
                    controller: _scrollController,//스크롤뷰 컨트롤러
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Color(0xFFE2E2E2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "기본음",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF3F3E3E),
                            ),
                          ),
                        ),

                        const Divider(color: Colors.black),

                        //기본음 9개
                        SizedBox(
                          height: 350,
                          child: GridView.count(
                            crossAxisCount: 3,
                            mainAxisSpacing: 28,
                            crossAxisSpacing: 17,
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,//전체 스크롤뷰에 맞게 줄어듦
                            physics: const NeverScrollableScrollPhysics(),
                            children: const [
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

                        //커스텀
                        SizedBox(
                          height: 100,
                          child: GridView.count(
                            crossAxisCount: 3,
                            mainAxisSpacing: 28,
                            crossAxisSpacing: 17,
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            children:  [
                              //커스텀 리스트 출력
                              for (final sound in customSounds)
                                CustomSoundBox(
                                  name:sound['name'],
                                  emoji:sound['emoji'],
                                  color:sound['color'],
                                ),
                              AddSoundBox(
                                onSoundAdded: (res){
                                  setState(() {
                                    customSounds.add(res);
                                  });
                                }
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigation(
        selectedTabIndex: 0, // "내소리" 탭이 선택된 상태
        onTabChanged: (index) {
          print("선택된 탭: $index");
        },
      ),
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
            borderRadius: BorderRadius.circular(16),
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

//커스텀 소리 박스 위젯
class CustomSoundBox extends StatelessWidget {
  final String name;
  final String emoji;
  final String color;

  const CustomSoundBox({
    super.key,
    required this.name,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context){
    final boxColor = color== "RED"? Colors.red:color=="GREEN"?Colors.green:Colors.blue;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 62,
          decoration: BoxDecoration(
            color:boxColor.withOpacity(0.1),
            border:Border.all(color:boxColor, width:1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color:Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

//소리 추가 버튼
class AddSoundBox extends StatelessWidget {

  //콜백 추가
  final Function(Map<String,dynamic>) onSoundAdded;

  const AddSoundBox({super.key,required this.onSoundAdded});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
    InkWell(
    borderRadius: BorderRadius.circular(16), // 터치 영역 둥글게
    onTap: () {
    Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const AddSounds()), //누르면 소리 추가하기 화면으로 넘어감
    );
    },
        child:Container(
          width: 80,
          height: 62,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            border: Border.all(color: Colors.grey, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(Icons.add, size: 32, color: Colors.grey),

          ),
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
