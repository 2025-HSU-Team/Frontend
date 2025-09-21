import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SoundState { idle, normal, warning, danger }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  SoundState _currentState = SoundState.idle;
  FlutterSoundRecorder? _recorder;
  FlutterSoundRecorder? _detectionRecorder;

  StreamSubscription? _recorderSub;
  StreamController<Uint8List>? _audioController;
  double _currentDb = 0.0; // 현재 데시벨 값
  static const double _normalThreshold = -20; // 정상 임계값 (조용한 환경)
  static const double _warningThreshold = -10; // 경고 임계값 (보통 소음)
  static const double _dangerThreshold = 0; // 위험 임계값 (큰 소음)

  // 소리 탐지 관련 변수들
  bool _isDetecting = false;
  Timer? _detectionTimer;
  String? _detectedSoundName;
  bool _showResult = false;
  DateTime? _lastDetectionTime; // 마지막 탐지 시간
  static const int _detectionCooldown = 5; // 탐지 간격 (초)
  
  // API 관련
  static const String _baseUrl = 'https://13.209.61.41.nip.io';
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _audioController = StreamController<Uint8List>();
    _loadAccessToken();
    _initMic();
    _startIdleAnimation();
  }

  void _startIdleAnimation() {
    _controller.repeat();
  }

  // SharedPreferences에서 액세스 토큰 로드
  Future<void> _loadAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      setState(() {
        _accessToken = token;
      });
      print('🔑 액세스 토큰 로드: ${token != null ? "성공" : "토큰 없음"}');
      if (token != null) {
        print('🔑 토큰 미리보기: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      print('❌ 토큰 로드 실패: $e');
    }
  }

  @override
  void dispose() {
    _recorderSub?.cancel();
    _detectionTimer?.cancel();
    _recorder?.closeRecorder();
    _detectionRecorder?.closeRecorder();
    _audioController?.close();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initMic() async {
    print('🎤 마이크 권한 확인 중...');
    final status = await Permission.microphone.status;
    print('🎤 현재 마이크 권한 상태: ${status.name}');
    
    if (!status.isGranted) {
      print('🎤 마이크 권한 요청 중...');
      final newStatus = await Permission.microphone.request();
      print('🎤 마이크 권한 요청 결과: ${newStatus.name}');
      
      if (!newStatus.isGranted) {
        print('❌ 마이크 권한이 거부되었습니다. 앱 설정에서 권한을 허용해주세요.');
        _showPermissionDialog();
        return;
      }
    }
    
    print('✅ 마이크 권한 허용됨. 녹음기 초기화 중...');
    
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    print('🎤 FlutterSoundRecorder 열기 완료');
    
    // 더 자주 업데이트하도록 설정
    await _recorder!.setSubscriptionDuration(const Duration(milliseconds: 100));
    print('⏱️ 구독 간격 설정 완료 (100ms)');
    
    print('✅ 녹음기 초기화 완료. 데시벨 측정 시작...');
    print('🎧 onProgress 리스너 설정 중...');
    _recorderSub = _recorder!.onProgress?.listen((event) {
      final db = event.decibels ?? 0.0;
      
      // 첫 번째 측정값 로그
      if (_currentDb == 0.0 && db != 0.0) {
        print('🎤 첫 번째 데시벨 측정: ${db.toStringAsFixed(1)} dB');
      }
      
      // 데시벨 값 로그 (중요한 변화만)
      if (db.isFinite && (db - _currentDb).abs() > 5.0) {
        print('🔊 데시벨 변화: ${_currentDb.toStringAsFixed(1)} → ${db.toStringAsFixed(1)} dB');
      }
      
      setState(() {
        _currentDb = db; // 현재 데시벨 값 업데이트
        
        // 소음 레벨에 따른 상태 결정
        SoundState newState;
        if (db < _normalThreshold) {
          newState = SoundState.idle;
        } else if (db < _warningThreshold) {
          newState = SoundState.normal;
        } else if (db < _dangerThreshold) {
          newState = SoundState.warning;
        } else {
          newState = SoundState.danger;
        }
        
        // 상태 변경시에만 로그 출력 (중요한 상태만)
        if (newState != _currentState) {
          if (newState == SoundState.warning || newState == SoundState.danger) {
            print('🎨 상태 변경: ${_currentState.name} → ${newState.name}');
          }
          _currentState = newState;
          if (_currentState == SoundState.idle) {
            _controller.repeat();
          } else {
            _controller.repeat();
          }
        }

        // 소음이 감지되면 자동으로 소리 탐지 시작
        _checkAutoDetection(db);
      });
    });
    print('🎙️ 실시간 녹음 시작 중...');
    await _recorder!.startRecorder(
      toStream: _audioController!.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 44100, // 더 높은 샘플링 레이트
      bitRate: 128000,   // 비트레이트 추가
    );
    print('✅ 실시간 녹음 시작 완료 - 데시벨 모니터링 활성화');
  }

  // 자동 소리 탐지 체크
  void _checkAutoDetection(double db) {
    // 탐지 중이거나 너무 자주 탐지하지 않도록 쿨다운 적용
    if (_isDetecting) {
      return;
    }
    
    final now = DateTime.now();
    if (_lastDetectionTime != null && 
        now.difference(_lastDetectionTime!).inSeconds < _detectionCooldown) {
      return;
    }

    // 소음 레벨이 일정 이상일 때 자동 탐지 시작
    if (db >= _warningThreshold) {
      print('🔍 소음 감지됨 (${db.toStringAsFixed(1)}dB) - 자동 소리 탐지 시작');
      print('🎯 임계값: ${_warningThreshold}dB, 현재: ${db.toStringAsFixed(1)}dB');
      _startSoundDetection();
      _lastDetectionTime = now;
    } else {
      // 임계값 근처에서 로그 출력 (디버깅용)
      if (db > _warningThreshold - 3) {
        print('👂 임계값 근접: ${db.toStringAsFixed(1)}dB (임계값: ${_warningThreshold}dB)');
      }
    }
  }

  // 소리 탐지 시작
  Future<void> _startSoundDetection() async {
    if (_isDetecting) return;
    
    // 마이크 권한 재확인
    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      print('❌ 마이크 권한이 없어서 소리 탐지를 시작할 수 없습니다.');
      _showPermissionDialog();
      return;
    }
    
    setState(() {
      _isDetecting = true;
      _showResult = false;
    });

    try {
      // 기존 실시간 측정 녹음기 일시 중지
      await _recorder?.stopRecorder();
      
      // 탐지용 녹음기 초기화
      _detectionRecorder = FlutterSoundRecorder();
      await _detectionRecorder!.openRecorder();
      print('🔧 탐지용 녹음기 초기화 완료');

      // 외부 저장소에 파일 저장 (접근 가능한 위치)
      final dir = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final path = p.join(dir.path, 'sound_detection_${DateTime.now().millisecondsSinceEpoch}.wav');

      // 5초간 녹음 시작 (더 긴 시간으로 실제 오디오 캡처 확률 증가)
      await _detectionRecorder!.startRecorder(
        toFile: path,
        codec: Codec.pcm16WAV,
        numChannels: 1,
        sampleRate: 44100, // CD 품질 샘플링 레이트
        bitRate: 128000,   // 비트레이트 설정
      );

      print('🔍 소리 탐지 시작 - 2초간 고품질 녹음 중...');

      // 2초 후 녹음 중지 및 분석
      print('⏰ 2초 타이머 시작됨 - 2초 후 분석 예정');
      _detectionTimer = Timer(const Duration(seconds: 2), () async {
        print('⏰ 2초 타이머 완료 - 분석 시작');
        await _stopAndAnalyzeSound(path);
      });

    } catch (e) {
      print('❌ 소리 탐지 시작 실패: $e');
      setState(() {
        _isDetecting = false;
      });
      // 실시간 측정 재시작
      _restartRealTimeMonitoring();
    }
  }

  // 녹음 중지 및 분석
  Future<void> _stopAndAnalyzeSound(String filePath) async {
    try {
      await _detectionRecorder?.stopRecorder();
      await _detectionRecorder?.closeRecorder();
      
      final file = File(filePath);
      if (await file.exists()) {
        final fileSize = await file.length();
        print('📁 녹음 파일 확인: ${file.path}');
        print('📏 실제 파일 크기: $fileSize bytes');
        
        // 파일 크기 검증 제거 - 모든 파일을 백엔드로 전송
        print('✅ 파일 확인 완료 - 백엔드 분석 진행');
        await _sendSoundToBackend(file);
      } else {
        print('❌ 녹음 파일이 생성되지 않았습니다: $filePath');
      }
    } catch (e) {
      print('❌ 녹음 중지 실패: $e');
    } finally {
      setState(() {
        _isDetecting = false;
      });
      // 실시간 측정 재시작
      _restartRealTimeMonitoring();
    }
  }


  // 더미 응답 테스트 (디버깅용)
  Future<void> _testDummyResponse() async {
    try {
      print('🧪 더미 응답 테스트 시작...');
      
      // 실제 API 응답 형식과 동일한 더미 데이터
      final dummyResponse = '''
{
  "isSuccess": true,
  "code": "SUCCESS_200",
  "httpStatus": 200,
  "message": "호출에 성공하였습니다.",
  "data": {
    "soundName": "Baby Cry",
    "emoji": null,
    "color": null,
    "similarity": -1.0,
    "alarmEnabled": true,
    "vibration": 1
  },
  "timeStamp": "2025-01-17 15:30:00"
}
''';
      
      print('📋 더미 응답 데이터: $dummyResponse');
      
      await _handleSoundDetectionResponse(dummyResponse);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('더미 응답 테스트 완료!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      print('❌ 더미 응답 테스트 실패: $e');
    }
  }


  // 실시간 측정 재시작
  Future<void> _restartRealTimeMonitoring() async {
    try {
      if (_recorder != null) {
        await _recorder!.startRecorder(
          toStream: _audioController!.sink,
          codec: Codec.pcm16,
          numChannels: 1,
          sampleRate: 44100,
          bitRate: 128000,
        );
        print('🔄 실시간 소음 측정 재시작됨');
      }
    } catch (e) {
      print('❌ 실시간 측정 재시작 실패: $e');
    }
  }

  // 백엔드로 소리 파일 전송
  Future<void> _sendSoundToBackend(File audioFile) async {
    try {
      print('🎯 소리 파일 분석 시작');
      print('📁 전송할 파일: ${audioFile.path}');
      print('📏 파일 크기: ${await audioFile.length()} bytes');
      
      // 토큰이 없으면 로그인 안내
      if (_accessToken == null) {
        print('⚠️ 액세스 토큰이 없습니다. 로그인이 필요합니다.');
        _showLoginRequiredDialog();
        return;
      }

      final uri = Uri.parse('$_baseUrl/api/sound/match');
      print('🌐 API URL: $uri');
      print('🔑 토큰 상태: ${_accessToken!.substring(0, 20)}...');
      
      final request = http.MultipartRequest('POST', uri);

      // Authorization 헤더 설정
      request.headers['Authorization'] = 'Bearer $_accessToken';
      print('🔐 Authorization 헤더 설정 완료');
      print('📋 요청 헤더: ${request.headers}');

      // 오디오 파일 추가
      final mimeType = lookupMimeType(audioFile.path) ?? 'audio/wav';
      final mediaType = MediaType.parse(mimeType);
      print('📎 MIME 타입: $mimeType');
      print('📎 미디어 타입: $mediaType');
      
      final filePart = await http.MultipartFile.fromPath(
        'file',
        audioFile.path,
        contentType: mediaType,
        filename: p.basename(audioFile.path),
      );
      request.files.add(filePart);
      print('📎 파일 첨부 완료: ${p.basename(audioFile.path)}');
      print('📎 첨부된 파일 크기: ${filePart.length} bytes');

      print('📤 백엔드로 소리 파일 전송 시작...');
      print('⏰ 전송 시작 시간: ${DateTime.now()}');

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      print('⏰ 응답 받은 시간: ${DateTime.now()}');
      print('📥 응답 상태 코드: ${response.statusCode}');
      print('📥 응답 헤더: ${response.headers}');
      print('📥 응답 본문 길이: ${response.body.length} characters');
      print('📥 응답 본문: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = response.body;
        print('✅ 백엔드 응답 성공!');
        print('✅ 응답 데이터: $responseData');
        
        await _handleSoundDetectionResponse(responseData);
      } else {
        print('❌ 백엔드 요청 실패!');
        print('❌ 상태 코드: ${response.statusCode}');
        print('❌ 오류 메시지: ${response.body}');
        print('❌ 응답 헤더: ${response.headers}');
        
        // 401 Unauthorized인 경우 토큰 재로드 시도
        if (response.statusCode == 401) {
          print('🔐 인증 토큰 만료 - 재로드 시도');
          await _loadAccessToken();
          _showErrorDialog('인증이 만료되었습니다. 다시 로그인해 주세요.');
        } else {
          _showErrorDialog('소리 분석에 실패했습니다. (${response.statusCode})');
        }
      }
    } catch (e) {
      print('❌ 백엔드 통신 오류: $e');
      _showErrorDialog('네트워크 오류가 발생했습니다.');
    }
  }

  // 소리 탐지 응답 처리
  Future<void> _handleSoundDetectionResponse(String responseBody) async {
    try {
      print('📋 응답 처리 시작...');
      print('📥 받은 응답 길이: ${responseBody.length} characters');
      print('📥 받은 응답: $responseBody');
      
      final Map<String, dynamic> response = jsonDecode(responseBody);
      print('📊 파싱된 응답: $response');
      print('📊 isSuccess: ${response['isSuccess']}');
      print('📊 code: ${response['code']}');
      print('📊 message: ${response['message']}');
      print('📊 data: ${response['data']}');
      
      if (response['isSuccess'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final soundName = data['soundName'] ?? '알 수 없는 소리';
        final alarmEnabled = data['alarmEnabled'] ?? false;
        final vibration = data['vibration'] ?? 0;
        final emoji = data['emoji'];
        final color = data['color'];
        
        print('✅ 분석 결과: $soundName');
        print('📊 알람 설정: $alarmEnabled, 진동: $vibration');
        print('📊 이모지: $emoji, 색상: $color');
        
        setState(() {
          _detectedSoundName = soundName;
          _showResult = true;
        });
        
        print('🎨 UI 상태 업데이트 완료 - _showResult: $_showResult');

        // 5초 후 결과 숨기기 (더 오래 표시)
        Timer(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _showResult = false;
            });
            print('🕐 결과 표시 시간 종료');
          }
        });

        print('🎉 소리 탐지 성공: $soundName');
        
        // 알람이 활성화된 경우 추가 처리 (예: 진동, 알림 등)
        if (alarmEnabled && vibration > 0) {
          _handleAlarmNotification(soundName, vibration);
        }
      } else {
        final message = response['message'] ?? '소리를 인식할 수 없습니다.';
        final code = response['code'] ?? 'UNKNOWN_ERROR';
        print('❌ 분석 실패: $message');
        print('❌ 오류 코드: $code');
        print('❌ 전체 응답: $response');
        _showErrorDialog(message);
      }
    } catch (e) {
      print('❌ 응답 처리 오류: $e');
      print('❌ 오류 타입: ${e.runtimeType}');
      print('❌ 스택 트레이스: ${e.toString()}');
      _showErrorDialog('응답 처리 중 오류가 발생했습니다.');
    }
  }

  // 알람 알림 처리
  void _handleAlarmNotification(String soundName, int vibration) {
    // 실제 앱에서는 HapticFeedback이나 진동 패키지 사용
    print('🔔 알람 알림: $soundName (진동: $vibration)');
    
    // 시각적 피드백을 위한 스낵바 표시
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔔 $soundName 감지됨!'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // 에러 다이얼로그 표시
  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 로그인 필요 다이얼로그 표시
  void _showLoginRequiredDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그인 필요'),
        content: const Text('소리 분석 기능을 사용하려면 로그인이 필요합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 로그인 화면으로 이동하는 로직 (필요시 구현)
              print('🔑 로그인 화면으로 이동');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6497FF),
            ),
            child: const Text('로그인', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 권한 필요 다이얼로그 표시
  void _showPermissionDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('마이크 권한 필요'),
        content: const Text('소리 탐지 기능을 사용하려면 마이크 권한이 필요합니다.\n\n앱 설정에서 마이크 권한을 허용해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings(); // 앱 설정 열기
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6497FF),
            ),
            child: const Text('설정 열기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // NOTE: This widget returns only the main content.
    // Header and Bottom navigations are provided by MainPage.
    return _buildMainContent();
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 메인 아이콘과 애니메이션
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final double t = _controller.value;
              return SizedBox(
                width: 300,
                height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // 펄스 링들
                    _buildPulseRing((t + 0.0) % 1.0),
                    _buildPulseRing((t + 0.33) % 1.0),
                    _buildPulseRing((t + 0.66) % 1.0),
                    // 중앙 원
                    _buildCenterCircle(),
                    // 중앙 아이콘
                    _buildCenterIcon(),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 40),
          
          // 상태 버튼
          _buildStatusButton(),
          
          const SizedBox(height: 20),
          
          // 자동 탐지 상태 표시
          _buildAutoDetectionStatus(),
          
          const SizedBox(height: 20),
          
          // 탐지 결과 표시
          if (_showResult) _buildDetectionResult(),
          
          const SizedBox(height: 20),
          
          // TMI 텍스트
          _buildTmiText(),
          
          const SizedBox(height: 20),
          
          // 테스트 버튼들
          _buildTestButtons(),
          
          // 하단 여백 추가 (BottomNavigation과 겹치지 않도록)
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // 상태별 색상 가져오기
  Color _getStateColor() {
    switch (_currentState) {
      case SoundState.idle:
        return Colors.blue;
      case SoundState.normal:
        return Colors.green;
      case SoundState.warning:
        return Colors.orange;
      case SoundState.danger:
        return Colors.red;
    }
  }

  // 상태별 아이콘 경로 가져오기
  String _getStateIconPath() {
    switch (_currentState) {
      case SoundState.idle:
        return 'assets/icon_blue.png';
      case SoundState.normal:
        return 'assets/icon_green.png';
      case SoundState.warning:
        return 'assets/icon_red.png';
      case SoundState.danger:
        return 'assets/icon_red.png';
    }
  }

  // 상태별 텍스트 가져오기
  String _getStateText() {
    switch (_currentState) {
      case SoundState.idle:
        return '대기중';
      case SoundState.normal:
        return '인식중';
      case SoundState.warning:
        return '인식중...';
      case SoundState.danger:
        return '인식중.....';
    }
  }

  // progress: 0.0 → 1.0
  Widget _buildPulseRing(double progress) {
    const double baseDiameter = 120.0;
    final double minScale = 1.0;
    final double maxScale = 2.5;
    final double scale = minScale + (maxScale - minScale) * progress;
    final double opacity = (1.0 - progress).clamp(0.0, 1.0);
    final Color stateColor = _getStateColor();

    return Transform.scale(
      scale: scale,
      child: Container(
        width: baseDiameter,
        height: baseDiameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: stateColor.withOpacity(0.3 * opacity),
            width: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildCenterCircle() {
    final Color stateColor = _getStateColor();
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: stateColor.withOpacity(0.1),
      ),
    );
  }

  Widget _buildCenterIcon() {
    final String iconPath = _getStateIconPath();

    return FutureBuilder<AssetBundleImageKey>(
      future: AssetImage(iconPath).obtainKey(const ImageConfiguration()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return Image.asset(iconPath, width: 100, height: 100);
        }
        // 아이콘 로드 실패 시 기본 아이콘 사용
        return Icon(
          Icons.hearing,
          size: 80,
          color: _getStateColor(),
        );
      },
    );
  }

  Widget _buildStatusButton() {
    final Color stateColor = _getStateColor();
    final String statusText = _getStateText();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: stateColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: stateColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // 자동 탐지 상태 표시
  Widget _buildAutoDetectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: _isDetecting ? Colors.orange[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDetecting ? Colors.orange[200]! : Colors.blue[200]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isDetecting ? Icons.mic : Icons.hearing,
            color: _isDetecting ? Colors.orange[600] : Colors.blue[600],
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            _isDetecting 
                ? '소리 분석 중...' 
                : '자동 소리 탐지 활성화',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _isDetecting ? Colors.orange[700] : Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  // 탐지 결과 표시
  Widget _buildDetectionResult() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '소리 탐지 완료!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '인식된 소리: $_detectedSoundName',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTmiText() {
    String tmiText;
    switch (_currentState) {
      case SoundState.idle:
        tmiText = 'tmi: 매우 조용한 환경입니다~';
        break;
      case SoundState.normal:
        tmiText = 'tmi: 정상적인 소음 레벨입니다~';
        break;
      case SoundState.warning:
        tmiText = 'tmi: 소음이 감지되면 자동으로 분석합니다~';
        break;
      case SoundState.danger:
        tmiText = 'tmi: 큰 소음이 감지되어 분석 중입니다!';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Text(
            tmiText,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '현재: ${_currentDb.toStringAsFixed(1)} dB (탐지 임계값: ${_warningThreshold}dB)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _accessToken != null ? Icons.verified_user : Icons.warning,
                size: 16,
                color: _accessToken != null ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                _accessToken != null ? '인증됨' : '로그인 필요',
                style: TextStyle(
                  fontSize: 12,
                  color: _accessToken != null ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (_lastDetectionTime != null) ...[
            const SizedBox(height: 4),
            Text(
              '마지막 탐지: ${_getTimeAgo(_lastDetectionTime!)}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[400],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 테스트 버튼들
  Widget _buildTestButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // 테스트 버튼들
          ElevatedButton(
            onPressed: () {
              _testDummyResponse();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              '테스트 응답',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 수동 소리 탐지 버튼
          ElevatedButton(
            onPressed: _isDetecting ? null : () {
              print('🔘 수동 소리 탐지 버튼 클릭');
              _startSoundDetection();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              _isDetecting ? '탐지 중...' : '수동 소리 탐지',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 시간 경과 표시
  String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}초 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else {
      return '${difference.inHours}시간 전';
    }
  }
}
