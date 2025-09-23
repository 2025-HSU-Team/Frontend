import 'package:flutter/material.dart';
import 'dart:math'; //파형 계산용 함수

import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared_components/bottom_navigation.dart';
import 'basic_screen.dart';

class AddSounds extends StatefulWidget {
  //initialData
  final Map<String, dynamic>? initialData; //수정 모드에서 전달된 데이터
  const AddSounds({super.key, this.initialData});

  @override
  State<AddSounds> createState() => _AddSoundsState();
}

class _AddSoundsState extends State<AddSounds>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  bool _isNotEmpty = false; //입력 여부 상태 저장
  String _selectedColor = "blue"; //기본 색상 파란색
  bool _isRecording = false; //마이크 버튼 상태(false=기본, true=녹음 중)

  //하단 탭 상태
  int _selectedTabIndex = 0;

  //이모지, 녹음파일
  String _emoji = '🔔'; //서버로 보낼 기본 이모지
  File? _audioFile; //녹음 파일
  final AudioRecorder _recorder = AudioRecorder(); //녹음기

  //실시간 음량 값
  double _amplitude = 0;

  //api 베이스
  static const String _baseUrl = 'https://13.209.61.41.nip.io';

  //파형 움직임 컨트롤러
  late AnimationController _waveController;

  //이모지 리스트 임의 값 50개
  final List<String> _emojiList = [
    '😀','😁','😂','🤣','😃','😄','😅','😆','😉','😊',
    '😋','😎','😍','😘','🥰','😗','😙','😚','🙂','🤗',
    '🤩','🤔','🤨','😐','😑','😶','🙄','😏','😣','😥',
    '😮','🤐','😯','😪','😫','🥱','😴','😌','😛','😜',
    '🤪','😝','🤑','🤠','😈','👿','👹','👺','💀','👻',
  ];

  //이모지 선택 모달
  void _selectEmoji() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SizedBox(
          height: 400,
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                "이모지 선택",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Divider(),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: _emojiList.length,
                  itemBuilder: (context, index) {
                    final e = _emojiList[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _emoji = e);
                        Navigator.pop(context);
                      },
                      child: Center(
                        child: Text(
                          e,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getMicBackgroundColor() {
    switch (_selectedColor) {
      case "blue":
        return const Color(0xFFD4E2FF);
      case "green":
        return const Color(0x66DFFFC6);
      case "red":
        return const Color(0x66FFD7D4);
      default:
        return const Color(0xFFD4E2FF);
    }
  }

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); //파형 계속 움직이도록 반복

    _controller.addListener(() {
      setState(() {
        _isNotEmpty = _controller.text.isNotEmpty;
      });
    });

    //초기값 세팅(수정 모드)
    if (widget.initialData != null) {
      _controller.text = widget.initialData!['name'] ?? '';
      _emoji = widget.initialData!['emoji'] ?? '🔔';
      _selectedColor = (widget.initialData!['color'] ?? 'blue').toLowerCase();
      _isNotEmpty = _controller.text.isNotEmpty;
    }

    _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
      if (!mounted) return;
      setState(() {
        _amplitude = (amp.current + 60).clamp(0, 60);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _recorder.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() => _selectedTabIndex = index);
  }

  //녹음 시작
  Future<void> _startRecord() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      final dir = await getTemporaryDirectory();
      final path = p.join(
          dir.path, 'custom_sound_${DateTime.now().millisecondsSinceEpoch}.wav');

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _audioFile = File(path);
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('마이크 권한이 거부되었습니다. 설정에서 허용해 주세요.')),
      );
    }
  }

  //녹음 종료
  Future<void> _stopRecord() async {
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      if (path != null) _audioFile = File(path);
    });
  }

  //업로드 (추가 or 수정)
  Future<Map<String, dynamic>?> _uploadSound() async {
    if (_controller.text.trim().isEmpty) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('소리 이름을 입력해 주세요.')),
      );
      return null;
    }
    if (_audioFile == null || !(_audioFile?.existsSync() ?? false)) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('녹음을 먼저 진행해 주세요.')),
      );
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("accessToken");
    if (token == null) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("로그인이 필요합니다.")),
      );
      return null;
    }

    //수정 모드인지 여부 확인
    final isEdit = widget.initialData != null;
    final soundId = widget.initialData?['id'];

    final uri = isEdit
        ? Uri.parse('$_baseUrl/api/sound/modify/$soundId') //수정 API
        : Uri.parse('$_baseUrl/api/sound/upload'); //추가 API
    final request = http.MultipartRequest(isEdit ? 'PUT' : 'POST', uri);

    request.fields['customName'] = _controller.text.trim();
    request.fields['emoji'] = _emoji;
    request.fields['color'] = _selectedColor.toUpperCase();

    final mimeType = lookupMimeType(_audioFile!.path) ?? 'audio/wav';
    final mediaType = MediaType.parse(mimeType);
    final filePart = await http.MultipartFile.fromPath(
      'file',
      _audioFile!.path,
      contentType: mediaType,
      filename: p.basename(_audioFile!.path),
    );
    request.files.add(filePart);

    request.headers['Authorization'] = 'Bearer $token';

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? '수정 완료!' : '업로드 완료!')),
      );

      final data = jsonDecode(resp.body); //서버 응답 파싱
      final sound = data["data"];         //응답 안에서 data 꺼내기

      return {
        'id': sound?["SoundId"] ?? sound?["soundId"],
        'soundKind': sound?["soundKind"] ?? "CUSTOM",
        'name': sound?["customName"] ?? _controller.text.trim(),
        'emoji': sound?["emoji"] ?? _emoji,
        'color': (sound?["color"] ?? _selectedColor).toUpperCase(),
      };
    } else {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패 (${resp.statusCode})')),
      );
      return null;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    Text(
                      widget.initialData != null ? "소리 수정하기" : "소리 추가하기",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),

                    //입력 필드
                    TextField(
                      controller: _controller,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                        _isNotEmpty ? FontWeight.bold : FontWeight.normal,
                        color: Colors.black,
                      ),
                      decoration: const InputDecoration(
                        hintText: "추가 할 소리명을 입력 해주세요.",
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                        border: UnderlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    //이모지 and 색상
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _selectEmoji,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6497FF),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            minimumSize: const Size(100, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "추가한 이모지 변경하기",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(_emoji,
                              style: const TextStyle(fontSize: 18)),
                        ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side:
                            const BorderSide(color: Color(0xFFCBCBCB)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: const Size(65, 26),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "소리명으로 보기",
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF3F3E3E),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 9),

                    //파동 색상 선택
                    Row(
                      children: [
                        const Text("파동 색상 선택",
                            style:
                            TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() => _selectedColor = "blue"),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFFB9D0FF),
                            child: _selectedColor == "blue"
                                ? const Icon(Icons.check,
                                size: 19, color: Color(0xFF0054FF))
                                : null,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() => _selectedColor = "green"),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFFCCFFA5),
                            child: _selectedColor == "green"
                                ? const Icon(Icons.check,
                                size: 14, color: Colors.green)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() => _selectedColor = "red"),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFFFFD7D4),
                            child: _selectedColor == "red"
                                ? const Icon(Icons.check,
                                size: 14, color: Colors.red)
                                : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 60),

                    //마이크 + 파형
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getMicBackgroundColor(),
                          ),
                          child: Center(
                            child: Image.asset(
                              _selectedColor == "blue"
                                  ? 'assets/images/bluemike.png'
                                  : _selectedColor == "green"
                                  ? 'assets/images/greenmike.png'
                                  : 'assets/images/redmike.png',
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        if (_isRecording)
                          AnimatedBuilder(
                            animation: _waveController,
                            builder: (context, child) {
                              return CustomPaint(
                                size: const Size(328, 120),
                                painter: WavePainter(
                                  _selectedColor,
                                  _amplitude,
                                  _waveController.value * 2 * pi,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    //녹음 버튼
                    GestureDetector(
                      onTap: () async {
                        if (_isRecording) {
                          await _stopRecord();
                        } else {
                          await _startRecord();
                        }
                        setState(() {});
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _isRecording
                                ? Container(
                              key: const ValueKey('rect'),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xffff1100),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            )
                                : Container(
                              key: const ValueKey('circle'),
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xffff1100),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    //저장 버튼
                    SizedBox(
                      width: 127,
                      height: 42,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6497FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        onPressed: () async {
                          final res = await _uploadSound();
                          if (!context.mounted || res == null) return;

                          // ✅ 저장 후 BasicScreen으로 이동
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const BasicScreen()),
                                (route) => false,
                          );
                        },
                        child: const Text(
                          "소리 저장하기",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.20,
                            letterSpacing: -0.35,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        selectedTabIndex: _selectedTabIndex,
        onTabChanged: _onTabChanged,
      ),
    );
  }
}

//파형
class WavePainter extends CustomPainter {
  final String color;
  final double amplitude;
  final double time;

  WavePainter(this.color, this.amplitude, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color == "blue"
          ? Colors.blue
          : color == "green"
          ? Colors.green
          : Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    for (double x = 0; x < size.width; x++) {
      final y = size.height / 2 + amplitude * sin((x / 10) + time);
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
