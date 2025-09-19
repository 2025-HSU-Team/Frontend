import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';

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
  

  StreamSubscription? _recorderSub;
  StreamController<Uint8List>? _audioController;
  double _currentDb = 0.0; // 현재 데시벨 값
  static const double _normalThreshold = -20; // 정상 임계값 (조용한 환경)
  static const double _warningThreshold = -10; // 경고 임계값 (보통 소음)
  static const double _dangerThreshold = 0; // 위험 임계값 (큰 소음)

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _audioController = StreamController<Uint8List>();
    _initMic();
    _startIdleAnimation();
  }

  void _startIdleAnimation() {
    _controller.repeat();
  }

  @override
  void dispose() {
    _recorderSub?.cancel();
    _recorder?.closeRecorder();
    _audioController?.close();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initMic() async {
    print('🎤 마이크 권한 요청 중...');
    final status = await Permission.microphone.request();
    print('🎤 마이크 권한 상태: ${status.name}');
    if (!status.isGranted) {
      print('❌ 마이크 권한이 거부되었습니다.');
      return;
    }
    print('✅ 마이크 권한 허용됨. 녹음기 초기화 중...');
    
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    
    // 더 자주 업데이트하도록 설정
    await _recorder!.setSubscriptionDuration(const Duration(milliseconds: 100));
    
    print('✅ 녹음기 초기화 완료. 데시벨 측정 시작...');
    _recorderSub = _recorder!.onProgress?.listen((event) {
      final db = event.decibels ?? 0.0;
      
      // 데시벨 값 로그 (변화가 있을 때만)
      if (db.isFinite && (db - _currentDb).abs() > 0.5) {
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
        
        // 상태 변경시에만 로그 출력
        if (newState != _currentState) {
          print('🎨 상태 변경: ${_currentState.name} → ${newState.name}');
          _currentState = newState;
          if (_currentState == SoundState.idle) {
            _controller.repeat();
          } else {
            _controller.repeat();
          }
        }
      });
    });
    await _recorder!.startRecorder(
      toStream: _audioController!.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 44100, // 더 높은 샘플링 레이트
      bitRate: 128000,   // 비트레이트 추가
    );
  }

  @override
  Widget build(BuildContext context) {
    // NOTE: This widget returns only the main content.
    // Header and Bottom navigations are provided by MainPage.
    return _buildMainContent();
  }

  Widget _buildMainContent() {
    return Center(
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
          
          // TMI 텍스트
          _buildTmiText(),
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
        tmiText = 'tmi: 소음이 조금 있네요~';
        break;
      case SoundState.danger:
        tmiText = 'tmi: 소음이 큽니다! 주의하세요~';
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
            '현재: ${_currentDb.toStringAsFixed(1)} dB',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
