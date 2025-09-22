import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// 모델들
import '../models/detection_state.dart';

// 서비스들
import '../services/audio_service.dart';
import '../services/backend_service.dart';

// 위젯들
import '../widgets/sound_detection_animation.dart';
import '../widgets/detection_status_widget.dart';
import '../widgets/control_buttons_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 서비스 인스턴스
  final AudioService _audioService = AudioService();
  final BackendService _backendService = BackendService();

  // 상태 관리
  DetectionState _currentState = DetectionState.idle;
  double _currentDb = 0.0;
  bool _isDetecting = false;
  String? _detectedSoundName;
  bool _showResult = false;
  Map<String, dynamic>? _lastDetectionResult; // 백엔드 응답 전체 저장
  DateTime? _lastDetectionTime;
  Timer? _detectionTimer;
  Timer? _resultTimer;

  // 상수
  static const int _detectionCooldown = 5;
  static const double _normalThreshold = -60;
  static const double _warningThreshold = -40;  // 실제 기기에서 소리 탐지 시작
  static const double _dangerThreshold = -20;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _resultTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  // ==================== 서비스 초기화 ====================
  
  Future<void> _initializeServices() async {
    // 백엔드 서비스 초기화
    await _backendService.initialize();
    
    // 콜백 설정
    _audioService.onAmplitudeChanged = _onAmplitudeChanged;
    _audioService.onFileRecorded = _onFileRecorded;
    _backendService.onSoundDetected = _onSoundDetected;
    _backendService.onError = _onError;
    
    // 오디오 서비스 초기화 및 실시간 모니터링 시작
    await _audioService.initialize();
    await _audioService.startRealTimeMonitoring();
  }

  // ==================== 콜백 함수들 ====================
  
  void _onAmplitudeChanged(double db) {
    setState(() {
      _currentDb = db;
      _currentState = _determineState(db);
      // _isDetecting은 파일 녹음 중일 때만 true로 설정
    });
    
    _checkAutoDetection(db);
  }

  void _onFileRecorded(String filePath) {
    print('🎵 파일 녹음 완료: $filePath');
    // analyzeSound는 _stopSoundDetection에서 호출하므로 여기서는 제거
  }

  void _onSoundDetected(Map<String, dynamic> result) {
    setState(() {
      _detectedSoundName = result['soundName'];
      _lastDetectionResult = result; // 전체 응답 저장
      _showResult = true;
    });
    
    // 5초 후 결과 숨김
    _resultTimer?.cancel();
    _resultTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showResult = false);
      }
    });
  }

  void _onError(String error) {
    _showErrorDialog(error);
  }

  // ==================== 상태 결정 ====================
  
  DetectionState _determineState(double db) {
    if (db < _normalThreshold) {
      return DetectionState.idle;
    } else if (db < _warningThreshold) {
      return DetectionState.normal;
    } else if (db < _dangerThreshold) {
      return DetectionState.warning;
    } else {
      return DetectionState.danger;
    }
  }

  // ==================== 자동 탐지 ====================
  
  void _checkAutoDetection(double db) {
    // 파일 녹음 중이 아닐 때만 자동 탐지
    if (_isDetecting) return;
    
    final now = DateTime.now();
    if (_lastDetectionTime != null &&
        now.difference(_lastDetectionTime!).inSeconds < _detectionCooldown) {
      return;
    }
    
    if (db >= _warningThreshold) {
      print('🔍 소음 감지됨 (${db.toStringAsFixed(1)}dB) - 자동 소리 탐지 시작');
      _startSoundDetection();
      _lastDetectionTime = now;
    }
  }

  // ==================== 소리 탐지 ====================
  
  Future<void> _startSoundDetection() async {
    if (_isDetecting) return;
    
    setState(() {
      _isDetecting = true;
      _currentState = DetectionState.detecting;
    });

    try {
      // 파일 녹음 시작
      final filePath = await _audioService.startFileRecording();
      if (filePath == null) {
        _showErrorDialog('녹음 시작에 실패했습니다.');
        return;
      }

      // 5초 후 녹음 중지
      _detectionTimer?.cancel();
      _detectionTimer = Timer(const Duration(seconds: 2), () async {
        await _stopSoundDetection(filePath);
      });
      
    } catch (e) {
      print('❌ 소리 탐지 시작 실패: $e');
      setState(() {
        _isDetecting = false;
        _currentState = _determineState(_currentDb);
      });
      _audioService.startRealTimeMonitoring();
    }
  }

  Future<void> _stopSoundDetection(String filePath) async {
    try {
      final file = await _audioService.stopFileRecording(filePath);
      if (file != null) {
        _backendService.analyzeSound(filePath);
      }
    } catch (e) {
      print('❌ 소리 탐지 중지 실패: $e');
    } finally {
      setState(() {
        _isDetecting = false;
        _currentState = _determineState(_currentDb);
      });
      await _audioService.startRealTimeMonitoring();
    }
  }

  // ==================== 수동 탐지 및 테스트 ====================
  
  Future<void> _startManualDetection() async {
    print('🎯 수동 소리 탐지 시작');
    await _startSoundDetection();
  }

  void _testBackendResponse() {
    print('🧪 테스트 응답 시뮬레이션');
    _backendService.simulateTestResponse();
  }

  Future<void> _createTestAudioFile() async {
    try {
      print('🧪 테스트 오디오 파일 생성 시작...');
      
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = p.join(dir.path, 'test_audio_$timestamp.wav');
      
      final file = File(filePath);
      await file.writeAsBytes(_generateTestWavData());
      
      final fileSize = await file.length();
      print('✅ 테스트 파일 생성 완료!');
      print('📁 경로: $filePath');
      print('📏 크기: $fileSize bytes (${(fileSize / 1024).toStringAsFixed(1)} KB)');
      
      _showFileInfoDialog(file);
      
    } catch (e) {
      print('❌ 테스트 파일 생성 실패: $e');
      _showErrorDialog('테스트 파일 생성 실패: $e');
    }
  }

  // ==================== 테스트 오디오 생성 ====================
  
  List<int> _generateTestWavData() {
    const sampleRate = 16000;
    const numChannels = 1;
    const bitsPerSample = 16;
    const duration = 5;
    final dataSize = sampleRate * numChannels * (bitsPerSample ~/ 8) * duration;
    final fileSize = 44 + dataSize;
    
    final bytes = <int>[];
    
    // RIFF 헤더
    bytes.addAll('RIFF'.codeUnits);
    bytes.addAll(_int32ToBytes(fileSize - 8));
    bytes.addAll('WAVE'.codeUnits);
    
    // fmt 청크
    bytes.addAll('fmt '.codeUnits);
    bytes.addAll(_int32ToBytes(16));
    bytes.addAll(_int16ToBytes(1));
    bytes.addAll(_int16ToBytes(numChannels));
    bytes.addAll(_int32ToBytes(sampleRate));
    bytes.addAll(_int32ToBytes(sampleRate * numChannels * (bitsPerSample ~/ 8)));
    bytes.addAll(_int16ToBytes(numChannels * (bitsPerSample ~/ 8)));
    bytes.addAll(_int16ToBytes(bitsPerSample));
    
    // data 청크
    bytes.addAll('data'.codeUnits);
    bytes.addAll(_int32ToBytes(dataSize));
    
    // 오디오 데이터 생성
    for (int i = 0; i < dataSize ~/ 2; i++) {
      final t = i / sampleRate;
      final frequency = 440.0;
      final amplitude = 0.3;
      
      final sample = (amplitude * math.sin(2 * math.pi * frequency * t) * 0.5 +
                     amplitude * (math.Random().nextDouble() - 0.5) * 0.1);
      
      final sampleInt = (sample * 32767).round().clamp(-32768, 32767);
      bytes.addAll(_int16ToBytes(sampleInt));
    }
    
    return bytes;
  }

  List<int> _int16ToBytes(int value) {
    return [value & 0xFF, (value >> 8) & 0xFF];
  }

  List<int> _int32ToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }

  // ==================== 다이얼로그 ====================
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          )
        ],
      ),
    );
  }

  void _showFileInfoDialog(File file) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🎵 파일 정보'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📁 경로: ${file.path}'),
            const SizedBox(height: 8),
            FutureBuilder<int>(
              future: file.length(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final sizeKB = (snapshot.data! / 1024).toStringAsFixed(1);
                  return Text('📏 크기: ${snapshot.data} bytes ($sizeKB KB)');
                }
                return const Text('📏 크기: 계산 중...');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  // ==================== UI 빌드 ====================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 상단 아이콘
              Container(
                margin: const EdgeInsets.only(top: 20, bottom: 30),
                child: Image.asset(
                  'assets/Icon.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
              
              // 메인 애니메이션
              SoundDetectionAnimation(
                state: _currentState,
                currentDb: _currentDb,
                isDetecting: _isDetecting,
                soundName: _detectedSoundName, // 감지된 소리명 전달
              ),
              const SizedBox(height: 30),
              
              // 상태 표시
              DetectionStatusWidget(
                state: _currentState,
                currentDb: _currentDb,
                isDetecting: _isDetecting,
              ),
              const SizedBox(height: 20),
              
              // 컨트롤 버튼들
              ControlButtonsWidget(
                isDetecting: _isDetecting,
                onManualDetection: _startManualDetection,
                onTestResponse: _testBackendResponse,
                onCreateTestFile: _createTestAudioFile,
              ),
              
              // 결과 표시
              if (_showResult) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '인식된 소리: $_detectedSoundName',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_lastDetectionResult != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '알림: ${_lastDetectionResult!['alarmEnabled'] == true ? '활성화' : '비활성화'}',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                              ),
                              if (_lastDetectionResult!['alarmEnabled'] == true) ...[
                                Text(
                                  '진동: 진동 ${_lastDetectionResult!['vibration'] ?? 1}',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 50),
              
              // TMI 텍스트
              const Text(
                'tmi: 빨간색은 무슨 의미에요~',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              
              const SizedBox(height: 50), // 하단 네비게이션을 위한 여백
            ],
          ),
        ),
      ),
    );
  }
}
