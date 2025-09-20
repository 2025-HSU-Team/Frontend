import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'add_sounds.dart';
import '../shared_components/bottom_navigation.dart';

class FixScreen extends StatefulWidget {
  const FixScreen({super.key});

  @override
  State<FixScreen> createState() => _FixScreenState();
}

class _FixScreenState extends State<FixScreen> {
  final ScrollController _scrollController = ScrollController();

  //커스텀 소리 리스트
  List<Map<String, dynamic>> customSounds = [];
  static const String _baseUrl = 'https://13.209.61.41.nip.io';

  //선택된 소리 id 리스트
  Set<int> selectedSoundIds = {};

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
                "id": sound["SoundId"],
                "name": sound["customName"],
                "emoji": sound["emoji"],
                "color": sound["color"],
              };
            }).toList();
          });
        }
      } else {
        debugPrint("소리 리스트 불러오기 실패: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("API 호출 에러: $e");
    }
  }

  //선택한 소리 수정하기
  Future<void> _editSelectedSound() async {
    if (selectedSoundIds.isEmpty) return;

    if (selectedSoundIds.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("한 번에 하나의 소리만 수정할 수 있습니다.")),
      );
      return;
    }

    final selectedId = selectedSoundIds.first;
    final selectedData =
    customSounds.firstWhere((s) => s['id'] == selectedId, orElse: () => {});

    if (selectedData.isEmpty) return;

    //AddSounds 페이지로 이동하면서 데이터 전달
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSounds(
          initialData: selectedData, //수정할 데이터 전달
        ),
      ),
    ).then((_) => _fetchCustomSounds()); //수정 후 새로고침
  }

  //선택한 소리 삭제
  Future<void> _deleteSelectedSounds() async {
    if (selectedSoundIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("선택하신 소리를 삭제 하시겠습니까?"),
        content: const Text("삭제된 소리는 복구가 불가능합니다."),
        actions: [
          TextButton(
            child: const Text("취소"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6497FF),
            ),
            child: const Text("삭제하기",
                style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("accessToken");

    for (final id in selectedSoundIds) {
      final url = Uri.parse("$_baseUrl/api/sound/delete?customSoundId=$id");
      final resp = await http.delete(
        url,
        headers: {
          "Authorization": "Bearer $token",
        },
      );
      debugPrint("삭제 요청 ($id) → ${resp.statusCode}");
    }

    setState(() {
      customSounds.removeWhere((s) => selectedSoundIds.contains(s['id']));
      selectedSoundIds.clear();
    });
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

          //수정 버튼
          Positioned(
            top: 89,
            right: 70,
            child: InkWell(
              onTap: _editSelectedSound,
              child: Image.asset(
                'assets/images/fix.png',
                width: 50,
                height: 45,
              ),
            ),
          ),

          //삭제 버튼
          Positioned(
            top: 89,
            right: 21,
            child: InkWell(
              onTap: _deleteSelectedSounds,
              child: Image.asset(
                'assets/images/trashcan.png',
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
                        //기본음
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E2E2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "기본음",
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF3F3E3E)),
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
                              SoundBox(
                                  image: 'assets/images/emergency.png',
                                  label: '비상 경보음',
                                  color: Colors.red),
                              SoundBox(
                                  image: 'assets/images/carsound.png',
                                  label: '자동차 경적 소리',
                                  color: Colors.red),
                              SoundBox(
                                  image: 'assets/images/fire.png',
                                  label: '화재 경보 소리',
                                  color: Colors.red),
                              SoundBox(
                                  image: 'assets/images/phonecall.png',
                                  label: '전화 벨소리',
                                  color: Colors.green),
                              SoundBox(
                                  image: 'assets/images/door.png',
                                  label: '문 여닫는 소리',
                                  color: Colors.green),
                              SoundBox(
                                  image: 'assets/images/bell.png',
                                  label: '초인종 소리',
                                  color: Colors.green),
                              SoundBox(
                                  image: 'assets/images/dog.png',
                                  label: '개 짖는 소리',
                                  color: Colors.blue),
                              SoundBox(
                                  image: 'assets/images/cat.png',
                                  label: '고양이 우는 소리',
                                  color: Colors.blue),
                              SoundBox(
                                  image: 'assets/images/babycry.png',
                                  label: '아기 우는 소리',
                                  color: Colors.blue),
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

                        //커스텀 리스트
                        SizedBox(
                          height: 150,
                          child: GridView.count(
                            crossAxisCount: 3,
                            mainAxisSpacing: 28,
                            crossAxisSpacing: 17,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            children: [
                              for (final sound in customSounds)
                                CustomSoundBox(
                                  id: sound['id'],
                                  name: sound['name'],
                                  emoji: sound['emoji'],
                                  color: sound['color'],
                                  isSelected:
                                  selectedSoundIds.contains(sound['id']),
                                  onSelect: (id) {
                                    setState(() {
                                      if (selectedSoundIds.contains(id)) {
                                        selectedSoundIds.remove(id);
                                      } else {
                                        selectedSoundIds.add(id);
                                      }
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
          print("선택된 탭: $index");
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
        Text(label,
            style:
            const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

//커스텀 소리 박스
class CustomSoundBox extends StatelessWidget {
  final int id;
  final String name;
  final String emoji;
  final String color;
  final bool isSelected; //선택 여부
  final Function(int) onSelect; //선택 콜백

  const CustomSoundBox({
    super.key,
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final boxColor = color == "RED"
        ? Colors.red
        : color == "GREEN"
        ? Colors.green
        : Colors.blue;

    return GestureDetector(
      onTap: () => onSelect(id), //클릭 시 선택 토글
      child: Stack(
        children: [
          Column(
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
                child:
                Center(child: Text(emoji, style: TextStyle(fontSize: 24))),
              ),
              const SizedBox(height: 4),
              Text(name,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w500)),
            ],
          ),
          //오른쪽 위 선택 동그라미
          Positioned(
            right: 15,
            top: 6,
            child: CircleAvatar(
              radius: 7,
              backgroundColor: isSelected ? Colors.red : Colors.white,
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
