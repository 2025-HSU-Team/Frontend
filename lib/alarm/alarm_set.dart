import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../shared_components/bottom_navigation.dart';
import '../pages/mainPage/mainPage.dart';
import '../custom/basic_screen.dart';

class AlarmSetScreen extends StatefulWidget {
  const AlarmSetScreen({super.key});

  @override
  State<AlarmSetScreen> createState() => _AlarmSetScreenState();
}

class _AlarmSetScreenState extends State<AlarmSetScreen> {
  static const String _baseUrl = 'https://13.209.61.41.nip.io';

  final Map<String, Map<String, dynamic>> defaultSoundInfo = {
    "DOG_BARK": {
      "label": "개 짖는 소리",
      "image": "assets/images/dog.png",
      "color": Colors.blue,
    },
    "CAT_MEOW": {
      "label": "고양이 우는 소리",
      "image": "assets/images/cat.png",
      "color": Colors.blue,
    },
    "BABY_CRY": {
      "label": "아기 우는 소리",
      "image": "assets/images/babycry.png",
      "color": Colors.blue,
    },
    "PHONE_RING": {
      "label": "전화 벨소리",
      "image": "assets/images/phonecall.png",
      "color": Colors.green,
    },
    "DOORBELL": {
      "label": "초인종 소리",
      "image": "assets/images/bell.png",
      "color": Colors.green,
    },
    "DOOR_OPEN_CLOSE": {
      "label": "문 여닫는 소리",
      "image": "assets/images/door.png",
      "color": Colors.green,
    },
    "FIRE_ALARM": {
      "label": "화재 경보 소리",
      "image": "assets/images/fire.png",
      "color": Colors.red,
    },
    "CAR_HORN": {
      "label": "자동차 경적 소리",
      "image": "assets/images/carsound.png",
      "color": Colors.red,
    },
    "SIREN": {
      "label": "비상 경보음",
      "image": "assets/images/emergency.png",
      "color": Colors.red,
    },
  };

  // 커스텀 소리 리스트
  List<Map<String, dynamic>> customSounds = [];

  // 알람 상태 저장
  Map<String, bool> alarmEnabled = {};
  Map<String, int> vibrationLevels = {};
  Map<String, int> soundIds = {};
  Map<String, String> soundKinds = {};

  // 하단 탭 상태
  int _selectedTabIndex = 2;

  @override
  void initState() {
    super.initState();
    _fetchAlarmSettings();
  }

  // 알람 설정 조회
  Future<void> _fetchAlarmSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken");
      if (token == null) return;

      final url = Uri.parse("$_baseUrl/api/sound/setting");
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["isSuccess"] == true) {
          final List<dynamic> sounds = data["data"];

          setState(() {
            customSounds.clear();
            alarmEnabled.clear();
            vibrationLevels.clear();
            soundIds.clear();
            soundKinds.clear();

            for (var s in sounds) {
              final soundId = s["soundId"];
              final soundKind = s["soundKind"];
              final soundName = s["soundName"];

              alarmEnabled[soundName] = s["alarmEnabled"] ?? false;
              vibrationLevels[soundName] = s["vibrationType"] ?? 1;
              soundIds[soundName] = soundId;
              soundKinds[soundName] = soundKind;

              if (soundKind == "CUSTOM") {
                customSounds.add({
                  "id": soundId,
                  "name": soundName,
                  "emoji": s["emoji"] ?? "",
                  "color": s["color"] ?? "BLUE",
                });
              }
            }
          });
        }
      } else {
        debugPrint("❌ 알람 설정 불러오기 실패: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ API 호출 에러: $e");
    }
  }

  // 알람 설정 업데이트
  Future<void> _updateAlarmSetting(
      String soundName, bool enabled, int vibration) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken");
      if (token == null) return;

      final soundId = soundIds[soundName];
      final soundKind = soundKinds[soundName];

      final url = Uri.parse("$_baseUrl/api/sound/setting/alarm");
      final body = jsonEncode({
        "soundKind": soundKind,
        "soundId": soundId,
        "alarmEnabled": enabled,
        "vibrationLevel": vibration,
      });

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: body,
      );

      if (response.statusCode != 200) {
        debugPrint("❌ 알람 설정 저장 실패: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ 알람 설정 저장 에러: $e");
    }
  }

  // 진동 설정 업데이트
  Future<void> _updateVibrationSetting(String soundName, int vibrationType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken");
      if (token == null) return;

      final soundId = soundIds[soundName];
      final soundKind = soundKinds[soundName];

      final url = Uri.parse("$_baseUrl/api/sound/setting/vibration");
      final body = jsonEncode({
        "soundKind": soundKind,
        "soundId": soundId,
        "vibrationType": vibrationType, // 1~5
      });

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: body,
      );

      if (response.statusCode != 200) {
        debugPrint("❌ 진동 설정 저장 실패: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ 진동 설정 저장 에러: $e");
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
                        _buildSectionTitle("알람"),
                        const SizedBox(height: 8),

                        // 기본음
                        for (var entry in defaultSoundInfo.entries)
                          _buildAlarmItem(
                            name: entry.key,
                            label: entry.value["label"],
                            image: entry.value["image"],
                            color: entry.value["color"],
                          ),

                        // 커스텀
                        for (var sound in customSounds)
                          _buildAlarmItem(
                            name: sound["name"],
                            emoji: sound["emoji"],
                            color: _mapColor(sound["color"]),
                          ),

                        const Divider(height: 40),
                        _buildSectionTitle("진동"),
                        const SizedBox(height: 8),

                        // 기본음 진동
                        for (var entry in defaultSoundInfo.entries)
                          if (alarmEnabled[entry.key] == true)
                            _buildVibrationItem(
                              name: entry.key,
                              label: entry.value["label"],
                              image: entry.value["image"],
                              color: entry.value["color"],
                            ),

                        // 커스텀 진동
                        for (var sound in customSounds)
                          if (alarmEnabled[sound["name"]] == true)
                            _buildVibrationItem(
                              name: sound["name"],
                              emoji: sound["emoji"],
                              color: _mapColor(sound["color"]),
                            ),

                        const SizedBox(height: 40),
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
        selectedTabIndex: _selectedTabIndex,
        onTabChanged: (index) {
          setState(() => _selectedTabIndex = index);
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

  // 섹션 타이틀
  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xff8e8e8e),
        ),
      ),
    );
  }

  // 알람 아이템
  Widget _buildAlarmItem({
    required String name,
    String? label,
    Color? color,
    String? image,
    String? emoji,
  }) {
    final c = color ?? Colors.blue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 62,
            decoration: BoxDecoration(
              color: c.withOpacity(0.1),
              border: Border.all(color: c, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: image != null
                  ? Image.asset(image, width: 30, height: 30)
                  : (emoji != null && emoji.isNotEmpty
                  ? Text(emoji, style: const TextStyle(fontSize: 24))
                  : const Icon(Icons.music_note, size: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label ?? name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3F3E3E),
              ),
            ),
          ),
          Switch(
            value: alarmEnabled[name] ?? false,
            activeColor: const Color(0xFF6497FF),
            activeTrackColor: const Color(0xFFD4E2FF),
            onChanged: (val) {
              setState(() {
                alarmEnabled[name] = val;
              });
              _updateAlarmSetting(name, val, vibrationLevels[name] ?? 1);
            },
          )
        ],
      ),
    );
  }

  // 진동 아이템
  Widget _buildVibrationItem({
    required String name,
    String? label,
    Color? color,
    String? image,
    String? emoji,
  }) {
    final c = color ?? Colors.blue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 62,
            decoration: BoxDecoration(
              color: c.withOpacity(0.1),
              border: Border.all(color: c, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: image != null
                  ? Image.asset(image, width: 30, height: 30)
                  : (emoji != null && emoji.isNotEmpty
                  ? Text(emoji, style: const TextStyle(fontSize: 24))
                  : const Icon(Icons.vibration, size: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label ?? name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          DropdownButton<int>(
            value: vibrationLevels[name] ?? 1,
            items: List.generate(
              5,
                  (i) => DropdownMenuItem(
                value: i + 1,
                child: Text("진동 ${i + 1}"),
              ),
            ),
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                vibrationLevels[name] = val;
              });
              _updateVibrationSetting(name, val);
            },
          )
        ],
      ),
    );
  }

  // 서버 색상 문자열을 Flutter Color로 매핑
  Color _mapColor(String? colorStr) {
    switch (colorStr?.toUpperCase()) {
      case "RED":
        return Colors.red;
      case "GREEN":
        return Colors.green;
      case "BLUE":
      default:
        return Colors.blue;
    }
  }
}
