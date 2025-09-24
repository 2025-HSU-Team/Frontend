import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/detection_state.dart';

class SoundDetectionAnimation extends StatefulWidget {
  final DetectionState state;
  final double currentDb;
  final bool isDetecting;
  final String? soundName; // 새로 추가된 파라미터
  final Color? detectionColor; // 인식중일 때 사용할 랜덤 색상
  final String? emoji; // 커스텀 소리의 이모지
  final String? soundColor; // 커스텀 소리의 색상 (RED, GREEN, BLUE)

  const SoundDetectionAnimation({
    super.key,
    required this.state,
    required this.currentDb,
    required this.isDetecting,
    this.soundName, // 옵셔널 파라미터
    this.detectionColor, // 옵셔널 파라미터
    this.emoji, // 옵셔널 파라미터
    this.soundColor, // 옵셔널 파라미터
  });

  @override
  State<SoundDetectionAnimation> createState() => _SoundDetectionAnimationState();
}

class _SoundDetectionAnimationState extends State<SoundDetectionAnimation> {
  late Color _detectionColor; // 인식중일 때 사용할 고정 색상

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        width: 380,  // 중앙 원 156px + 주변 원들을 위한 영역 확장
        height: 380, // 중앙 원 156px + 주변 원들을 위한 영역 확장
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 데시벨에 따른 원들
            _buildDecibelCircles(),
            // 중앙 원
            _buildCenterCircle(),
            // 중앙 아이콘 (귀와 눈)
            _buildCenterIcon(),
          ],
        ),
      ),
    );
  }

  // 데시벨에 따른 원들 생성
  Widget _buildDecibelCircles() {
    final soundColor = _getSoundColor();
    final circles = <Widget>[];
    
    // 데시벨 범위를 7개 구간으로 나누기 (-40dB ~ 0dB)
    // 조용한 도서관 기준(-40dB)을 1개 원으로, 0dB 이상을 7개 원으로 설정
    final minDb = -40.0; // 조용한 도서관 기준
    final maxDb = 0.0;   // 최대 데시벨
    final dbRange = maxDb - minDb; // 40dB 범위
    final normalizedDb = ((widget.currentDb - minDb) / dbRange).clamp(0.0, 1.0); // 0.0 ~ 1.0
    final activeCircles = (normalizedDb * 6 + 1).ceil().clamp(1, 7); // 1개~7개 원
    
    // 중앙 원 크기 (156px로 설정)
    final centerSize = 156.0;
    
    // 7개의 원 생성 (가장 안쪽부터)
    for (int i = 0; i < 7; i++) {
      final isActive = i < activeCircles;
      final circleSize = centerSize + (i + 1) * 25; // 각 원은 25px씩 커짐 (30px → 25px)
      
      // 안쪽부터 바깥쪽으로 갈수록 투명도가 점점 감소 (0.9 → 0.3)
      final opacity = isActive ? (0.9 - (i * 0.1)).clamp(0.3, 0.9) : 0.0;
      
      circles.add(
        Container(
          width: circleSize,
          height: circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: soundColor.withOpacity(opacity),
              width: 2,
          ),
        ),
      ),
      );
    }
    
    return Stack(
      alignment: Alignment.center,
      children: circles,
    );
  }

  Widget _buildCenterCircle() {
    // 중앙 원 크기를 156px로 설정
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
    final iconPath = _getStateIcon();
    
    // 이모지 모드인 경우
    if (iconPath == 'EMOJI_MODE') {
    return Container(
        width: 120,
        height: 120,
        child: Center(
          child: Text(
            widget.emoji ?? '',
            style: const TextStyle(fontSize: 60),
          ),
        ),
      );
    }
    
    // 일반 아이콘 모드
    return Container(
      width: 120,  // 156의 약 77% 크기로 조정
      height: 120, // 156의 약 77% 크기로 조정
      child: Image.asset(
        iconPath,
        width: 120,
        height: 120,
        fit: BoxFit.contain,
      ),
    );
  }

  String _getStateIcon() {
    // 이모지가 있는 경우 (커스텀 소리) - 가장 우선순위로 특별한 플래그 반환
    if (widget.emoji != null && widget.emoji!.isNotEmpty) {
      return 'EMOJI_MODE';
    }
    
    // soundName이 있고 "Unknown"이 아닌 경우에만 특정 아이콘 사용 (탐지 성공)
    if (widget.soundName != null && widget.soundName != "Unknown" && widget.soundName != "알 수 없음") {
      final iconPath = _getSoundNameIcon(widget.soundName!);
      // _getSoundNameIcon이 기본 아이콘을 반환했다면 (커스텀 소리), 랜덤 아이콘 사용
      if (iconPath == 'assets/icon_blue.png' && widget.detectionColor != null) {
        return _getColorMatchingIcon(widget.detectionColor!);
      }
      return iconPath;
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

  // 서버에서 받은 색상 문자열을 Flutter Color로 매핑
  Color _mapServerColor(String colorStr) {
    switch (colorStr.toUpperCase()) {
      case "RED":
        return const Color(0xFFFFD7D4); // 빨간색
      case "GREEN":
        return const Color(0xFF9FFF55); // 초록색
      case "BLUE":
      default:
        return const Color(0xFFD4E2FF); // 파란색
    }
  }

  Color _getSoundColor() {
    // 이모지가 있는 경우 (커스텀 소리) - 서버에서 받은 색상 사용
    if (widget.emoji != null && widget.emoji!.isNotEmpty && widget.soundColor != null) {
      return _mapServerColor(widget.soundColor!);
    }
    
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
