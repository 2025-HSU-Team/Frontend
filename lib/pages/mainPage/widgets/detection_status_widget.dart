import 'package:flutter/material.dart';
import '../models/detection_state.dart';

class DetectionStatusWidget extends StatefulWidget {
  final DetectionState state;
  final double currentDb;
  final bool isDetecting;
  final Color? detectionColor; // 인식중일 때 사용할 랜덤 색상
  final String? detectedSoundName; // 감지된 소리명
  final String? detectedEmoji; // 감지된 커스텀 소리의 이모지

  const DetectionStatusWidget({
    super.key,
    required this.state,
    required this.currentDb,
    required this.isDetecting,
    this.detectionColor, // 옵셔널 파라미터
    this.detectedSoundName, // 옵셔널 파라미터
    this.detectedEmoji, // 옵셔널 파라미터
  });

  @override
  State<DetectionStatusWidget> createState() => _DetectionStatusWidgetState();
}

class _DetectionStatusWidgetState extends State<DetectionStatusWidget>
    with TickerProviderStateMixin {
  late AnimationController _textController;
  String _detectionText = '인식중';
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // 전체 사이클 5초
    );
  }

  @override
  void didUpdateWidget(DetectionStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isDetecting && !oldWidget.isDetecting) {
      _startDetectionAnimation();
    } else if (!widget.isDetecting && oldWidget.isDetecting) {
      _stopDetectionAnimation();
    }
    
    // 감지된 소리 정보가 변경되었을 때 텍스트 업데이트
    if (widget.detectedSoundName != oldWidget.detectedSoundName ||
        widget.detectedEmoji != oldWidget.detectedEmoji) {
      if (!widget.isDetecting) {
        setState(() {
          _detectionText = _getStatusText();
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _startDetectionAnimation() {
    _dotCount = 0;
    _textController.addListener(_updateDetectionText);
    _textController.repeat();
  }

  void _stopDetectionAnimation() {
    _textController.removeListener(_updateDetectionText);
    _textController.stop();
    setState(() {
      _detectionText = _getStatusText();
      _dotCount = 0;
    });
  }
  
  // 상태에 따른 텍스트 결정
  String _getStatusText() {
    // 백엔드에서 올바른 응답이 전달되었을 때
    if (widget.detectedSoundName != null && 
        widget.detectedSoundName != "Unknown" && 
        widget.detectedSoundName != "알 수 없음") {
      
      // 커스텀 소리일 경우 (이모지가 있는 경우)
      if (widget.detectedEmoji != null && widget.detectedEmoji!.isNotEmpty) {
        return widget.detectedSoundName!; // 커스텀 소리명 반환
      }
      
      // 기본 소리일 경우 한글 소리명 반환
      return _getKoreanSoundName(widget.detectedSoundName!);
    }
    
    // 그 외의 경우 기본 대기 상태
    return '자동 탐지 대기 중';
  }
  
  // 영어 소리명을 한글 소리명으로 변환
  String _getKoreanSoundName(String soundName) {
    switch (soundName) {
      // 빨간색 (비상/경고)
      case "FIRE_ALARM":
      case "Fire/Smoke Alarm":
      case "Fire Alarm":
        return "화재 경보 소리";
      case "SIREN":
      case "Siren":
      case "Emergency":
        return "비상 경보음";
      case "CAR_HORN":
      case "Car Honk":
      case "Car Horn":
        return "자동차 경적 소리";
      
      // 초록색 (일상)
      case "PHONE_RING":
      case "Phone Ring":
        return "전화 벨소리";
      case "DOOR_OPEN_CLOSE":
      case "Door In-Use":
      case "Door":
        return "문 여닫는 소리";
      case "DOORBELL":
      case "Doorbell":
        return "초인종 소리";
      case "Knocking":
        return "노크 소리";
      
      // 파란색 (동물)
      case "DOG_BARK":
      case "Dog Bark":
        return "개 짖는 소리";
      case "CAT_MEOW":
      case "Cat Meow":
        return "고양이 우는 소리";
      case "BABY_CRY":
      case "Baby Cry":
        return "아기 우는 소리";
      
      default:
        return soundName; // 변환되지 않은 경우 원본 반환
    }
  }

  void _updateDetectionText() {
    // 전체 사이클 5초: 0초(0개) → 1초(1개) → 2초(2개) → 3초(3개) → 4초(4개) → 5초(0개)
    final progress = _textController.value; // 0.0 ~ 1.0
    _dotCount = (progress * 5).floor() % 5; // 0, 1, 2, 3, 4
    
    final dots = '.' * _dotCount;
    final text = '인식중$dots';
    
    setState(() {
      _detectionText = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 상태 표시 (파란색으로 고정)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.blue,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // 중앙 정렬
            children: [
              Image.asset(
                'assets/images/bluemike.png',
                width: 20,
                height: 20,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _detectionText,
                  textAlign: TextAlign.center, // 텍스트 중앙 정렬
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStateColor() {
    switch (widget.state) {
      case DetectionState.idle:
        return Colors.blue;
      case DetectionState.normal:
        return Colors.green;
      case DetectionState.warning:
        return Colors.orange;
      case DetectionState.danger:
        return Colors.red;
      case DetectionState.detecting:
        return Colors.purple;
    }
  }
}
