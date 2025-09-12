import 'package:flutter/material.dart';
import '../shared_components/bottom_navigation.dart';

//기본 알람 9개
final List<Map<String, dynamic>> allDefaultSounds = [
  {"name": "비상 경보음", "color": Colors.red, "image": "assets/images/emergency.png"},
  {"name": "자동차 경적 소리", "color": Colors.red, "image": "assets/images/carsound.png"},
  {"name": "화재 경보 소리", "color": Colors.red, "image": "assets/images/fire.png"},
  {"name": "전화 벨소리", "color": Colors.green, "image": "assets/images/phonecall.png"},
  {"name": "문 여닫는 소리", "color": Colors.green, "image": "assets/images/door.png"},
  {"name": "초인종 소리", "color": Colors.green, "image": "assets/images/bell.png"},
  {"name": "개 짖는 소리", "color": Colors.blue, "image": "assets/images/dog.png"},
  {"name": "고양이 우는 소리", "color": Colors.blue, "image": "assets/images/cat.png"},
  {"name": "아기 우는 소리", "color": Colors.blue, "image": "assets/images/babycry.png"},
];

class AlarmSetScreen extends StatefulWidget {
  const AlarmSetScreen({super.key});

  @override
  State<AlarmSetScreen> createState() => _AlarmSetScreenState();
}

class _AlarmSetScreenState extends State<AlarmSetScreen> {
  //알람 ON/OFF 상태
  final Map<String, bool> alarmEnabled = {};

  //커스텀 소리 리스트
  final List<Map<String, dynamic>> customSounds = [];

  //하단 탭 상태
  int _selectedTabIndex = 2;

  @override
  void initState() {
    super.initState();
    //기본음은 모두 OFF로 시작
    for (var sound in allDefaultSounds) {
      alarmEnabled[sound["name"]] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();

    return Scaffold(
      backgroundColor: const Color(0xFFD4E2FF),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 44),
              //상단 로고
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
            top: 137,
            left: (MediaQuery.of(context).size.width - 328) / 2,
            child: Container(
              width: 328,
              height: 580,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Scrollbar(
                  controller: scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //알람 섹션
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), //안쪽 여백
                          decoration: BoxDecoration(
                            color: Colors.white, // 흰색 배경
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3), //그림자 색 (회색, 투명도 30%)
                                blurRadius: 6, //퍼짐 정도
                                offset: const Offset(0, 3), //수직 방향 그림자 위치
                              ),
                            ],
                          ),
                          child: const Text(
                            "알람",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff8e8e8e), //텍스트 색
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                        Column(
                          children: [
                            for (var sound in allDefaultSounds)
                              _buildAlarmItem(
                                name: sound["name"],
                                color: sound["color"],
                                image: sound["image"],
                              ),
                            for (var sound in customSounds)
                              _buildAlarmItem(
                                name: sound["name"],
                                color: sound["color"] == "RED"
                                    ? Colors.red
                                    : sound["color"] == "GREEN"
                                    ? Colors.green
                                    : Colors.blue,
                                emoji: sound["emoji"],
                              ),
                          ],
                        ),

                        const Divider(height: 40),

                        //진동 섹션
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), //안쪽 여백
                          decoration: BoxDecoration(
                            color: Colors.white, // 흰색 배경
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3), //그림자 색 (회색, 투명도 30%)
                                blurRadius: 6, //퍼짐 정도
                                offset: const Offset(0, 3), //수직 방향 그림자 위치
                              ),
                            ],
                          ),
                          child: const Text(
                            "진동",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff8e8e8e), //텍스트 색
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: [
                            for (var sound in allDefaultSounds)
                              if (alarmEnabled[sound["name"]] == true)
                                _buildVibrationItem(
                                  name: sound["name"],
                                  color: sound["color"],
                                  image: sound["image"],
                                ),
                            for (var sound in customSounds)
                              if (alarmEnabled[sound["name"]] == true)
                                _buildVibrationItem(
                                  name: sound["name"],
                                  color: sound["color"] == "RED"
                                      ? Colors.red
                                      : sound["color"] == "GREEN"
                                      ? Colors.green
                                      : Colors.blue,
                                  emoji: sound["emoji"],
                                ),
                          ],
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

      //하단
      bottomNavigationBar: BottomNavigation(
        selectedTabIndex: _selectedTabIndex,
        onTabChanged: (index) {
          setState(() => _selectedTabIndex = index);
          print("선택된 탭: $index");
        },
      ),
    );
  }

  //알람
  Widget _buildAlarmItem({
    required String name,
    required Color color,
    String? image,
    String? emoji,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 62,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              border: Border.all(color: color, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: image != null
                  ? Image.asset(image, width: 30, height: 30)
                  : Text(emoji ?? "🔔", style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF3F3E3E))),
          ),
          Switch(
            value: alarmEnabled[name] ?? false,
            activeColor: Color(0xFF6497FF), //동그라미 색
            activeTrackColor: Color(0xFFD4E2FF), //켜졌을 때 배경 색
            inactiveThumbColor: Color(0xFFFEFEFE), //꺼졌을 때 동그라미
            inactiveTrackColor: Color(0xFFD9D9D9), //꺼졌을 때 배경
            onChanged: (val) {
              setState(() {
                alarmEnabled[name] = val;
              });
            },
          )
        ],
      ),
    );
  }

  //진동
  Widget _buildVibrationItem({
    required String name,
    required Color color,
    String? image,
    String? emoji,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          //기존 박스 그대로
          Container(
            width: 80,
            height: 62,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              border: Border.all(color: color, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: image != null
                  ? Image.asset(image, width: 30, height: 30)
                  : Text(emoji ?? "🔔", style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black)),
          ),
          DropdownButton<String>(
            value: "진동 1",
            items: const [
              DropdownMenuItem(value: "진동 1", child: Text("진동 1")),
              DropdownMenuItem(value: "진동 2", child: Text("진동 2")),
              DropdownMenuItem(value: "진동 3", child: Text("진동 3")),
            ],
            onChanged: (val) {},
          )
        ],
      ),
    );
  }
}
