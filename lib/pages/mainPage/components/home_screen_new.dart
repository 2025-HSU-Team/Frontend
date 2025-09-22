import 'package:flutter/material.dart';
import 'dart:async';

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
              
              // 컨트롤 버튼들 (현재 비어있음)
              const ControlButtonsWidget(),
              
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
