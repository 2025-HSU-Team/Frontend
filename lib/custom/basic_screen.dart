import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'add_sounds.dart';
import '../shared_components/bottom_navigation.dart';
import 'delete_screen.dart';
import 'fix_screen.dart';

import '../pages/mainPage/mainPage.dart';
import '../alarm/alarm_set.dart';

class BasicScreen extends StatefulWidget {
  const BasicScreen({super.key});

  @override
  State<BasicScreen> createState() => _BasicScreenState();
}

class _BasicScreenState extends State<BasicScreen> {
  final ScrollController _scrollController = ScrollController();

  //커스텀 소리 리스트
  List<Map<String, dynamic>> customSounds = [];
  static const String _baseUrl = 'https://13.209.61.41.nip.io';

  @override
  void initState() {
    super.initState();
    _fetchCustomSounds(); //화면 열릴 때 API 호출
  }

  Future<void> _fetchCustomSounds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken");

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("로그인이 필요합니다.")),
        );
        return;
      }

      final url = Uri.parse("$_baseUrl/api/sound");
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["isSuccess"] == true) {
          final List<dynamic> sounds = data["data"];
          setState(() {
            customSounds = sounds.map((sound) {
              return {
                "name": sound["customName"],
                "emoji": sound["emoji"],
                "color": sound["color"],
              };
            }).toList();
          });
        }
        //오류 확인하기 위해
      } else {
        debugPrint("❌ 소리 리스트 불러오기 실패: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ API 호출 에러: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4E2FF),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 44),
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

          //쓰레기통
          Positioned(
            top: 89,
            right: 21,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DeleteScreen()),
                ).then((_) => _fetchCustomSounds()); //삭제 후 새로고침
              },
              child: Image.asset(
                'assets/images/trashcan.png',
                width: 50,
                height: 45,
              ),
            ),
          ),

          //수정 화면 이동
          Positioned(
            top: 89,
            right: 70,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FixScreen()),
                ).then((_) => _fetchCustomSounds()); //자동 새로고침 되는 부분
              },
              child: Image.asset(
                'assets/images/fix.png',
                width: 50,
                height: 45,
              ),
            ),
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
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 기본음
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E2E2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "기본음",
                            style: TextStyle(fontSize: 12, color: Color(0xFF3F3E3E)),
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
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            children: const [
                              SoundBox(image: 'assets/images/emergency.png', label: '비상 경보음', color: Colors.red),
                              SoundBox(image: 'assets/images/carsound.png', label: '자동차 경적 소리', color: Colors.red),
                              SoundBox(image: 'assets/images/fire.png', label: '화재 경보 소리', color: Colors.red),
                              SoundBox(image: 'assets/images/phonecall.png', label: '전화 벨소리', color: Colors.green),
                              SoundBox(image: 'assets/images/door.png', label: '문 여닫는 소리', color: Colors.green),
                              SoundBox(image: 'assets/images/bell.png', label: '초인종 소리', color: Colors.green),
                              SoundBox(image: 'assets/images/dog.png', label: '개 짖는 소리', color: Colors.blue),
                              SoundBox(image: 'assets/images/cat.png', label: '고양이 우는 소리', color: Colors.blue),
                              SoundBox(image: 'assets/images/babycry.png', label: '아기 우는 소리', color: Colors.blue),
                            ],
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4E2FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "커스텀",
                            style: TextStyle(fontSize: 12, color: Color(0xFF3A70DA)),
                          ),
                        ),
                        const Divider(color: Colors.black),

                        // 커스텀 리스트
                        SizedBox(
                          height: 240,
                          child: GridView.count(
                            crossAxisCount: 3,
                            mainAxisSpacing: 28,
                            crossAxisSpacing: 17,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            children: [
                              for (final sound in customSounds)
                                CustomSoundBox(
                                  name: sound['name'],
                                  emoji: sound['emoji'],
                                  color: sound['color'],
                                ),
                              AddSoundBox(
                                onSoundAdded: (res) {
                                  setState(() {
                                    customSounds.add(res);
                                  });
                                },
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
        selectedTabIndex: 0,
        onTabChanged: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BasicScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainPage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AlarmSetScreen()),
            );
          }
        },
      ),
    );
  }
}

//기본 소리 박스
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 62,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(child: Image.asset(image, width: 30, height: 30)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

//커스텀 소리 박스
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
  Widget build(BuildContext context) {
    final boxColor = color == "RED"
        ? Colors.red
        : color == "GREEN"
        ? Colors.green
        : Colors.blue;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 62,
          decoration: BoxDecoration(
            color: boxColor.withOpacity(0.1),
            border: Border.all(color: boxColor, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
        ),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }
}


//소리 추가 버튼
class AddSoundBox extends StatelessWidget {
  final Function(Map<String, dynamic>) onSoundAdded;

  const AddSoundBox({super.key, required this.onSoundAdded});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddSounds()),
            ).then((result) {
              if (result != null && result is Map<String, dynamic>) {
                onSoundAdded(result);
              }
            });
          },
          child: Container(
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
        const Text("소리 추가하기", style: TextStyle(fontSize: 10, color: Colors.black54)),
      ],
    );
  }
}
