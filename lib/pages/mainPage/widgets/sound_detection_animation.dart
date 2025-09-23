import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/detection_state.dart';

class SoundDetectionAnimation extends StatefulWidget {
  final DetectionState state;
  final double currentDb;
  final bool isDetecting;
  final String? soundName; // 새로 추가된 파라미터
  final Color? detectionColor; // 인식중일 때 사용할 랜덤 색상

  const SoundDetectionAnimation({
    super.key,
    required this.state,
    required this.currentDb,
    required this.isDetecting,
    this.soundName, // 옵셔널 파라미터
    this.detectionColor, // 옵셔널 파라미터
  });

  @override
  State<SoundDetectionAnimation> createState() => _SoundDetectionAnimationState();
}

class _SoundDetectionAnimationState extends State<SoundDetectionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Color _detectionColor; // 인식중일 때 사용할 고정 색상

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _controller.repeat();
    _detectionColor = _getRandomColor(); // 초기 랜덤 색상 설정
  }

  @override
  void didUpdateWidget(SoundDetectionAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 인식 상태가 변경될 때마다 새로운 랜덤 색상 생성
    if (widget.isDetecting != oldWidget.isDetecting) {
      if (widget.isDetecting) {
        _detectionColor = _getRandomColor(); // 인식 시작 시 새로운 랜덤 색상
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        width: 302,  // 최대 애니메이션 크기로 제한
        height: 302, // 최대 애니메이션 크기로 제한
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 펄스 링들
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                final t = _controller.value;
                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    _buildPulseRing((t + 0.0) % 1.0),
                    _buildPulseRing((t + 0.33) % 1.0),
                    _buildPulseRing((t + 0.66) % 1.0),
                  ],
                );
              },
            ),
            // 중앙 원
            _buildCenterCircle(),
            // 중앙 아이콘 (귀와 눈)
            _buildCenterIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildPulseRing(double progress) {
    // 데시벨에 따라 최대 크기 조절 (-160dB ~ 0dB 범위를 156 ~ 302 픽셀로 매핑)
    final dbRange = 160.0; // -160dB에서 0dB까지
    final normalizedDb = (widget.currentDb + dbRange) / dbRange; // 0.0 ~ 1.0
    final maxDiameter = 156 + (normalizedDb * 146); // 156 ~ 302 픽셀
    
    // 중앙 원(156px)에서 시작해서 최대 크기까지 퍼져 나가는 방식
    final startDiameter = 156.0;
    final diameter = startDiameter + (maxDiameter - startDiameter) * progress;
    
    // 펄스 링은 점점 옅어지는 효과 (초록색 40%부터, 빨간색/파란색 100%부터)
    final soundColor = _getSoundColor();
    final isGreen = soundColor.value == const Color(0xFF9FFF55).value;
    final startOpacity = isGreen ? 0.4 : 1.0;
    final opacity = (startOpacity * (1.0 - progress * progress)).clamp(0.0, 1.0);
    
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: soundColor.withOpacity(opacity),
          width: 6,
        ),
      ),
    );
  }

  Widget _buildCenterCircle() {
    // 중앙 원 크기를 156x156으로 고정
    final centerSize = 156.0;
    
    // 중앙 원은 고정 색상 (초록색 40%, 빨간색/파란색 100%)
    final soundColor = _getSoundColor();
    final isGreen = soundColor.value == const Color(0xFF9FFF55).value;
    final centerOpacity = isGreen ? 0.4 : 1.0;
    
    return Container(
      width: centerSize,
      height: centerSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: soundColor.withOpacity(centerOpacity), // 중앙 원은 고정 색상
        border: Border.all(
          color: soundColor.withOpacity(0.3),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildCenterIcon() {
    return Container(
      width: 120,  // 156의 약 77% 크기로 조정
      height: 120, // 156의 약 77% 크기로 조정
      child: Image.asset(
        _getStateIcon(),
        width: 120,
        height: 120,
        fit: BoxFit.contain,
      ),
    );
  }

  String _getStateIcon() {
    // soundName이 있고 "Unknown"이 아닌 경우에만 특정 아이콘 사용 (탐지 성공)
    if (widget.soundName != null && widget.soundName != "Unknown" && widget.soundName != "알 수 없음") {
      return _getSoundNameIcon(widget.soundName!);
    }
    
    // 그 외의 경우 (앱 시작, 탐지 시작, 탐지 실패)에는 랜덤 색상과 매칭되는 아이콘 사용
    if (widget.detectionColor != null) {
      return _getColorMatchingIcon(widget.detectionColor!);
    }
    
    // 기본 대기 상태일 때는 기본 아이콘 사용
    return 'assets/icon_blue.png';
  }

  // 색상과 매칭되는 아이콘 경로를 반환하는 헬퍼 메서드
  String _getColorMatchingIcon(Color color) {
    if (color.value == const Color(0xFF9FFF55).value) {
      return 'assets/icon_green.png';
    } else if (color.value == const Color(0xFFFFD7D4).value) {
      return 'assets/icon_red.png';
    } else {
      return 'assets/icon_blue.png';
    }
  }

  // 랜덤 색상을 반환하는 헬퍼 메서드
  Color _getRandomColor() {
    final colors = [
      const Color(0xFF9FFF55), // 초록색 (#9FFF55)
      const Color(0xFFFFD7D4), // 빨간색 (#FFD7D4)
      const Color(0xFFD4E2FF), // 파란색 (#D4E2FF)
    ];
    return colors[math.Random().nextInt(colors.length)];
  }

  Color _getSoundColor() {
    // soundName이 있고 "Unknown"이 아닌 경우에만 해당 소리의 색상 사용 (탐지 성공)
    if (widget.soundName != null && widget.soundName != "Unknown" && widget.soundName != "알 수 없음" && widget.soundName != "UNKNOWN") {
      switch (widget.soundName) {
        // 빨간색 (비상/경고)
        case "FIRE_ALARM":
        case "Fire/Smoke Alarm":
        case "Fire Alarm":
        case "화재 경보 소리":
        case "SIREN":
        case "Siren":
        case "Emergency":
        case "비상 경보음":
        case "CAR_HORN":
        case "Car Honk":
        case "Car Horn":
        case "자동차 경적 소리":
          return const Color(0xFFFFD7D4); // 빨간색
        
        // 초록색 (일상)
        case "PHONE_RING":
        case "Phone Ring":
        case "전화 벨소리":
        case "DOOR_OPEN_CLOSE":
        case "Door In-Use":
        case "Door":
        case "문 여닫는 소리":
        case "DOORBELL":
        case "Doorbell":
        case "초인종 소리":
        case "Knocking": // 노크도 문 소리와 같은 초록색
          return const Color(0xFF9FFF55); // 초록색
        
        // 파란색 (동물)
        case "DOG_BARK":
        case "Dog Bark":
        case "개 짖는 소리":
        case "CAT_MEOW":
        case "Cat Meow":
        case "고양이 우는 소리":
        case "BABY_CRY":
        case "Baby Cry":
        case "아기 우는 소리":
          return const Color(0xFFD4E2FF); // 파란색
      }
    }
    
    // 그 외의 경우 (앱 시작, 탐지 시작, 탐지 실패)에는 랜덤 색상 사용
    if (widget.detectionColor != null) {
      return widget.detectionColor!;
    }
    
    // 기본 색상 (soundName이 없거나 매칭되지 않는 경우)
    return const Color(0xFF9FFF55); // 기본 초록색
  }

  String _getSoundNameIcon(String soundName) {
    // 백엔드에서 반환하는 모든 값들을 처리
    switch (soundName) {
      // 강아지 소리
      case "DOG_BARK":
      case "Dog Bark":
      case "개 짖는 소리":
        return 'assets/images/dog.png';
      
      // 고양이 소리
      case "CAT_MEOW":
      case "Cat Meow":
      case "고양이 우는 소리":
        return 'assets/images/cat.png';
      
      // 아기 우는 소리
      case "BABY_CRY":
      case "Baby Cry":
      case "아기 우는 소리":
        return 'assets/images/babycry.png';
      
      // 전화 벨소리
      case "PHONE_RING":
      case "Phone Ring":
      case "전화 벨소리":
        return 'assets/images/phonecall.png';
      
      // 초인종 소리
      case "DOORBELL":
      case "Doorbell":
      case "초인종 소리":
        return 'assets/images/bell.png';
      
      // 문 여닫는 소리
      case "DOOR_OPEN_CLOSE":
      case "Door In-Use":
      case "Door":
      case "문 여닫는 소리":
        return 'assets/images/door.png';
      
      // 화재 경보 소리
      case "FIRE_ALARM":
      case "Fire/Smoke Alarm":
      case "Fire Alarm":
      case "화재 경보 소리":
        return 'assets/images/fire.png';
      
      // 자동차 경적 소리
      case "CAR_HORN":
      case "Car Honk":
      case "Car Horn":
      case "자동차 경적 소리":
        return 'assets/images/carsound.png';
      
      // 비상 경보음
      case "SIREN":
      case "Siren":
      case "Emergency":
      case "비상 경보음":
        return 'assets/images/emergency.png';
      
      // Unknown
      case "UNKNOWN":
      case "Unknown":
      case "알 수 없음":
        // Unknown은 랜덤 아이콘 사용
        return _getColorMatchingIcon(widget.detectionColor ?? const Color(0xFFD4E2FF));
      
      // 추가 소리들 (기존 코드 유지)
      case "Knocking":
        return 'assets/images/door.png';
      case "Microwave":
        return 'assets/images/fix.png';
      case "Laptop":
        return 'assets/images/laptop.jpg';
      case "Trash":
        return 'assets/images/trashcan.png';
      case "SOS":
        return 'assets/images/sosaw.png';
      
      default:
        // 알 수 없는 소리명인 경우 파란색 아이콘 사용
        return 'assets/icon_blue.png';
    }
  }

  // 기존 메서드 (호환성을 위해 유지)
  Color _getStateColor() {
    return _getSoundColor();
  }
}
