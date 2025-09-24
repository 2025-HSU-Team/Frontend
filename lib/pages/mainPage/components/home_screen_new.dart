import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

// 모델들
import '../models/detection_state.dart';

// 서비스들
import '../services/audio_service.dart';
import '../services/backend_service.dart';
import '../services/vibration_service.dart';

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
  Color? _detectionColor; // 인식중일 때 사용할 랜덤 색상
  bool _isAnalyzing = false; // 분석 중 플래그 (중복 통신 방지)
  String? _detectedEmoji; // 감지된 커스텀 소리의 이모지
  String? _detectedSoundColor; // 감지된 커스텀 소리의 색상
  String _currentTmi = ''; // 현재 표시할 TMI

  // 상수
  static const int _detectionCooldown = 5;
  static const double _normalThreshold = -50;   // 대기 상태 (매우 조용)
  static const double _warningThreshold = -30;  // 소리 탐지 시작 (일반 대화 수준)
  static const double _dangerThreshold = -10;   // 위험 상태 (시끄러움)

  // TMI 리스트
  final List<String> _tmiList = [
    '파란색이면 생물 소리입니다! 주변을 확인해 보세요!',
    '초록색이면 생활 소리입니다! 상황을 살펴보세요!',
    '빨간색이면 긴급 상황입니다! 조심하세요!',
    '소리가 가까울수록 원이 커져요!',
    //'커스텀 소리를 등록하면 나만의 소리 탐지를 할 수 있어요!',
    '진동 패턴으로 소리를 구분할 수 있어요!',
    '한눈에 보기 쉽도록 소리별 이모지가 표시돼요!',
    //'일상생활 소리 탐지는 필요에 따라 ON/OFF 할 수 있어요!',
    '탐지되는 소리별로 다른 진동 패턴을 설정해보세요!',
    '커스텀 소리를 생활 패턴에 맞게 등록하세요!',
  ];

  // 랜덤 색상 생성
  Color _getRandomColor() {
    final colors = [
      const Color(0xFF9FFF55), // 초록색
      const Color(0xFFFFD7D4), // 빨간색
      const Color(0xFFD4E2FF), // 파란색
    ];
    return colors[math.Random().nextInt(colors.length)];
  }

  // 랜덤 TMI 선택
  String _getRandomTmi() {
    return _tmiList[math.Random().nextInt(_tmiList.length)];
  }

  // 상단 아이콘 경로 결정 (Icon.png로 고정)
  String _getTopIconPath() {
    return 'assets/Icon.png';
  }

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 랜덤 색상 설정
    _detectionColor = _getRandomColor();
    print('🚀 앱 시작 - 초기 랜덤 색상 설정: ${_detectionColor!.value.toRadixString(16)}');
    
    // 초기 TMI 설정
    _currentTmi = _getRandomTmi();
    
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
      // 결과 표시 중에는 상태 변경하지 않음
      if (!_showResult) {
        _currentState = _determineState(db);
      }
      // _isDetecting은 파일 녹음 중일 때만 true로 설정
    });
    
    _checkAutoDetection(db);
  }

  void _onFileRecorded(String filePath) {
    print('🎵 파일 녹음 완료: $filePath');
    // analyzeSound는 _stopSoundDetection에서 호출하므로 여기서는 제거
  }

  void _onSoundDetected(Map<String, dynamic> result) {
    _isAnalyzing = false; // 분석 완료 플래그 리셋
    
    setState(() {
      _detectedSoundName = result['soundName'];
      _detectedEmoji = result['emoji']; // 커스텀 소리 이모지 저장
      _detectedSoundColor = result['color']; // 커스텀 소리 색상 저장
      _lastDetectionResult = result; // 전체 응답 저장
      // Unknown이 아닌 경우에만 결과 표시
      _showResult = result['soundName'] != 'Unknown' && result['soundName'] != '알 수 없음';
    });
    
    // 알림이 활성화되어 있고 Unknown이 아닌 경우 진동 실행
    if (result['alarmEnabled'] == true && 
        result['soundName'] != 'Unknown' && 
        result['soundName'] != '알 수 없음') {
      final vibrationLevel = result['vibration'] ?? 1;
      print('📳 진동 실행: ${result['soundName']} (레벨: $vibrationLevel)');
      VibrationService().vibrate(vibrationLevel);
    }
    
    // Unknown이 아닌 경우에만 5초 후 결과 숨김
    if (_showResult) {
      _resultTimer?.cancel();
      _resultTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          print('⏰ 결과 표시 완료 - 새로운 랜덤 색상 선택');
          setState(() {
            _showResult = false;
            _detectedSoundName = null; // 결과 초기화
            _detectedEmoji = null; // 이모지 초기화
            _detectedSoundColor = null; // 색상 초기화
            // 5초 후 새로운 랜덤 색상 선택
            _detectionColor = _getRandomColor();
            print('🎨 새로운 랜덤 색상 선택: ${_detectionColor!.value.toRadixString(16)}');
          });
        }
      });
    } else {
      // Unknown인 경우 기존 색상 유지
      print('❓ Unknown 결과 - 기존 색상 유지: ${_detectionColor?.value.toRadixString(16)}');
    }
  }

  void _onError(String error) {
    _isAnalyzing = false; // 분석 실패 시에도 플래그 리셋
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
    // 파일 녹음 중, 결과 표시 중, 분석 중일 때는 자동 탐지 차단
    if (_isDetecting || _showResult || _isAnalyzing) return;
    
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
    if (_isDetecting || _showResult) return; // 결과 표시 중일 때도 차단
    
    // 매번 새로운 랜덤 색상 생성 (탐지 시작 시마다)
    _detectionColor = _getRandomColor();
    print('🎨 탐지 시작 - 새로운 랜덤 색상 생성: ${_detectionColor!.value.toRadixString(16)}');
    
    // 소리 인식 시작 시 TMI도 새로 설정
    _currentTmi = _getRandomTmi();
    print('💡 소리 인식 시작 - 새로운 TMI 설정: $_currentTmi');
    
    setState(() {
      _isDetecting = true;
      _currentState = DetectionState.detecting;
    });
    
    print('🎙️ 소리 탐지 시작 (색상: ${_detectionColor!.value.toRadixString(16)})');

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
      if (file != null && !_isAnalyzing) {
        _isAnalyzing = true;
        print('🔍 백엔드 분석 시작 (중복 방지)');
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                    // 상단 아이콘 (80x80)
                    Container(
                      margin: const EdgeInsets.only(bottom: 34), // 중앙 원과의 간격 34px
                      child: Image.asset(
                        _getTopIconPath(),
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                    
                    // 메인 애니메이션
                    SoundDetectionAnimation(
                      state: _currentState,
                      currentDb: _currentDb,
                      isDetecting: _isDetecting,
                      soundName: _detectedSoundName, // 감지된 소리명 전달
                      detectionColor: _detectionColor, // 인식중일 때 사용할 랜덤 색상
                      emoji: _detectedEmoji, // 커스텀 소리 이모지 전달
                      soundColor: _detectedSoundColor, // 커스텀 소리 색상 전달
                    ),
                    const SizedBox(height: 0), // 중앙 원과 인식중... 컴포넌트 사이 간격 30px
                    
                    // 상태 표시
                    DetectionStatusWidget(
                      state: _currentState,
                      currentDb: _currentDb,
                      isDetecting: _isDetecting,
                      detectionColor: _detectionColor, // 인식중일 때 사용할 랜덤 색상
                      detectedSoundName: _detectedSoundName, // 감지된 소리명
                      detectedEmoji: _detectedEmoji, // 감지된 커스텀 소리의 이모지
                    ),
                    const SizedBox(height: 1), // 인식중... 컴포넌트와 TMI 컴포넌트 사이 간격 19px
                    
                    // 컨트롤 버튼들 (현재 비어있음)
                    const ControlButtonsWidget(),
                    
                    
                    const SizedBox(height: 35), // TMI 텍스트를 5px 아래로 이동
                    
                    // TMI 텍스트
                    Text(
                      'tmi: $_currentTmi',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
