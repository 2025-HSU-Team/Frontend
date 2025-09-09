import 'package:flutter/material.dart';
import 'dart:math'; //파형 계산용 함수

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

class AddSounds extends StatefulWidget {
  const AddSounds({super.key});

  @override
  State<AddSounds> createState() => _AddSoundsState();
}

class _AddSoundsState extends State<AddSounds> {
  final TextEditingController _controller = TextEditingController();
  bool _isNotEmpty = false; //입력 여부 상태 저장
  String _selectedColor = "blue"; //기본 색상 파란색
  bool _isRecording = false; //마이크 버튼 상태(false=기본, true=녹음 중)

  //이모지,녹음파일
  String _emoji='🔔'; //서버로 보낼 기본 이모지
  File? _audioFile; //녹음 파일
  final AudioRecorder _recorder= AudioRecorder(); //녹음기

  // 🟢 추가: 실시간 음량 값 저장
  double _amplitude = 0;

  //api 베이스
  static const String _baseUrl='https://13.209.61.41.nip.io';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _isNotEmpty = _controller.text.isNotEmpty; //입력되면 true
      });
    });

    //녹음 중 실시간으로 파형
    _recorder.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((amp) {
      if (mounted) {
        setState(() {
          //데시벨 0~60 범위로 변환해서 파형 크기로 사용
          _amplitude = (amp.current + 60).clamp(0, 60);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _recorder.dispose();
    super.dispose();
  }

  //녹음 시작
  Future<void> _startRecord() async {
    //마이크 되는지 체크 코드
    final status = await Permission.microphone.request();
    print('🎤 마이크 권한 상태: $status');

    if (status.isGranted) {
      final dir = await getTemporaryDirectory();
      final path = p.join(
        dir.path,
        'custom_sound_${DateTime.now().millisecondsSinceEpoch}.wav',
      );
      print('📂 녹음 경로: $path');

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

      print('✅ 녹음 시작됨');
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

  //업로드 (multipart/form-data)
  Future<Map<String, dynamic>?> _uploadSound() async {
    //필드 검증
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

    final uri = Uri.parse('$_baseUrl/api/sound/upload'); //업로드 API 엔드포인트 생성
    final request = http.MultipartRequest('POST', uri);//HTTP POST 요청 준비

    //customName, emoji, color(RED|BLUE|GREEN), file(.wav)
    request.fields['customName'] = _controller.text.trim(); //백엔드에 보낼 소리 이름
    request.fields['emoji'] = _emoji; //이모지
    request.fields['color'] = _selectedColor.toUpperCase(); //색상

    //오디오 파일을 백엔드 API에 업로드하기 위한 파일 파트
    final mimeType = lookupMimeType(_audioFile!.path) ?? 'audio/wav';
    final mediaType = MediaType.parse(mimeType);
    final filePart = await http.MultipartFile.fromPath(
      'file', //필드 이름
      _audioFile!.path, //실제 파일 경로
      contentType: mediaType, //MIME 타입
      filename: p.basename(_audioFile!.path), //파일 이름
    );
    request.files.add(filePart); //파일 파트를 API 요청에 추가

    // 필요 시 인증 토큰
    // request.headers['Authorization'] = 'Bearer <token>';

    final streamed = await request.send(); //API 요청 전송
    final resp = await http.Response.fromStream(streamed); //응답 수신

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('업로드 완료!')),
      );
      //성공 시 이전 화면에서 사용하도록 간단한 결과 반환
      return {                                  //성공 시 백엔드에 보낸 정보 반환
        'name': _controller.text.trim(),
        'emoji': _emoji,
        'color': _selectedColor.toUpperCase(),
      };
    } else {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업로드 실패 (${resp.statusCode})')),
      );
      return null;
    }
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
                        fontWeight: _isNotEmpty
                            ? FontWeight.bold
                            : FontWeight.normal, //입력된 글자
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
                                  child:  Center(
                                    child: Text("이모지 선택 화면(추후 연결)\n현재: $_emoji",
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

                        //파동 색상 선택
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

                            //파랑 버튼
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

                            //초록 버튼
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

                            //빨강 버튼
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
                      ],
                    ),
                    const SizedBox(height: 60),

                    //마이크 and 파형 Stack
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        //마이크 아이콘 (뒤)
                        Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFD4E2FF),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/mike.png',
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        //파형 (앞) amplitude 전달
                        if (_isRecording)
                          CustomPaint(
                            size: const Size(328, 120),
                            painter: WavePainter(_selectedColor, _amplitude),
                          ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    //녹음 빨간 버튼
                    GestureDetector(
                      onTap: () async {//실제 녹음 토글
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
                          color: Colors.white, //바깥 흰색 원
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
                                borderRadius: BorderRadius.circular(6), //네모
                              ),
                            )
                                : Container(
                              key: const ValueKey('circle'),
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xffff1100),
                                shape: BoxShape.circle, //원
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    //소리 저장하기 버튼
                    SizedBox(
                      width: 127,
                      height: 42,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6497FF), //버튼 색
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50), //짝 둥글게
                          ),
                        ),
                        onPressed: () async {//업로드 연결
                          final res = await _uploadSound();
                          if (!context.mounted || res == null) return;
                          Navigator.of(context).pop(res);//성공 시 결과 전달(커스텀 영역 추가용)
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
    );
  }
}

//파형 CustomPainter
class WavePainter extends CustomPainter {
  final String color;
  final double amplitude; //소리 크기
  WavePainter(this.color, this.amplitude);

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
      //amplitude 크기 반영
      final y = size.height / 2 + amplitude * sin(x / 10);
      if (x == 0) { //첫 점 보정(끊김 방지)
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
