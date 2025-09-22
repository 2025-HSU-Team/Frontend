import 'package:flutter/material.dart';
import '../models/detection_state.dart';

class SoundDetectionAnimation extends StatefulWidget {
  final DetectionState state;
  final double currentDb;
  final bool isDetecting;
  final String? soundName; // 새로 추가된 파라미터

  const SoundDetectionAnimation({
    super.key,
    required this.state,
    required this.currentDb,
    required this.isDetecting,
    this.soundName, // 옵셔널 파라미터
  });

  @override
  State<SoundDetectionAnimation> createState() => _SoundDetectionAnimationState();
}

class _SoundDetectionAnimationState extends State<SoundDetectionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 펄스 링들
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final t = _controller.value;
              return Stack(
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
    );
  }

  Widget _buildPulseRing(double progress) {
    const double baseDiameter = 150;
    final scale = 1.0 + (3.0 - 1.0) * progress;
    final opacity = (1.0 - progress * progress).clamp(0.0, 1.0);
    final (_, borderColor, _) = _getCircleColors();
    
    return Transform.scale(
      scale: scale,
      child: Container(
        width: baseDiameter,
        height: baseDiameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor.withOpacity(0.4 * opacity),
            width: 6,
          ),
        ),
      ),
    );
  }

  Widget _buildCenterCircle() {
    final (centerColor, borderColor, opacity) = _getCircleColors();
    
    // 초록색(normal)의 경우 그라데이션 효과 적용
    if (widget.state == DetectionState.normal) {
      return Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              centerColor.withOpacity(0.4), // 중앙: 40%
              centerColor.withOpacity(0.2), // 중간: 20%
              centerColor.withOpacity(0.05), // 바깥: 5%
              Colors.transparent, // 가장 바깥: 투명
            ],
            stops: const [0.0, 0.4, 0.7, 1.0],
          ),
          border: Border.all(
            color: borderColor.withOpacity(0.3),
            width: 2,
          ),
        ),
      );
    }
    
    // 다른 색상들은 단색으로 표시
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: centerColor.withOpacity(opacity),
        border: Border.all(
          color: borderColor.withOpacity(0.3),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildCenterIcon() {
    return Container(
      width: 80,
      height: 80,
      child: Image.asset(
        _getStateIcon(),
        width: 80,
        height: 80,
        fit: BoxFit.contain,
      ),
    );
  }

  String _getStateIcon() {
    // soundName이 있을 때는 해당하는 아이콘 사용
    if (widget.soundName != null) {
      return _getSoundNameIcon(widget.soundName!);
    }
    
    // soundName이 없을 때는 기존 상태 기반 아이콘 사용
    switch (widget.state) {
      case DetectionState.idle:
        return 'assets/icon_blue.png';
      case DetectionState.normal:
        return 'assets/icon_green.png';
      case DetectionState.warning:
        return 'assets/icon_blue.png'; // 경고시에도 파란색 사용
      case DetectionState.danger:
        return 'assets/icon_red.png';
      case DetectionState.detecting:
        return 'assets/icon_red.png'; // 감지중일 때도 빨간색
    }
  }

  String _getSoundNameIcon(String soundName) {
    // alarm_set.dart의 기본 소리 목록과 매칭
    switch (soundName) {
      case "Dog Bark":
        return 'assets/images/dog.png';
      case "Cat Meow":
        return 'assets/images/cat.png';
      case "Baby Cry":
        return 'assets/images/babycry.png';
      case "Emergency":
        return 'assets/images/emergency.png';
      case "Car Horn":
        return 'assets/images/carsound.png';
      case "Fire Alarm":
        return 'assets/images/fire.png';
      case "Phone Ring":
        return 'assets/images/phonecall.png';
      case "Door":
        return 'assets/images/door.png';
      case "Doorbell":
        return 'assets/images/bell.png';
      case "Knocking":
        return 'assets/images/door.png'; // 노크 소리는 문 소리 아이콘 사용
      case "Microwave":
        return 'assets/images/fix.png'; // 전자레인지는 수리 아이콘 사용
      default:
        // 기본 소리가 아닌 경우 웃는 얼굴 이모지 사용
        return 'assets/icon_blue.png';
    }
  }

  // 새로운 색상 시스템: (중앙색, 테두리색, 투명도)
  (Color centerColor, Color borderColor, double opacity) _getCircleColors() {
    switch (widget.state) {
      case DetectionState.idle:
        return (
          const Color(0xFFD4E2FF), // #D4E2FF 100%
          const Color(0xFFD4E2FF),
          1.0
        );
      case DetectionState.normal:
        return (
          const Color(0xFF9FFF55), // #9FFF55 40%부터 점점 옅어짐
          const Color(0xFF9FFF55),
          0.4
        );
      case DetectionState.warning:
        return (
          const Color(0xFFD4E2FF), // #D4E2FF 100%
          const Color(0xFFD4E2FF),
          1.0
        );
      case DetectionState.danger:
        return (
          const Color(0xFFFFD7D4), // #FFD7D4 100%
          const Color(0xFFFFD7D4),
          1.0
        );
      case DetectionState.detecting:
        return (
          const Color(0xFFFFD7D4), // #FFD7D4 100%
          const Color(0xFFFFD7D4),
          1.0
        );
    }
  }

  // 기존 메서드 (호환성을 위해 유지)
  Color _getStateColor() {
    final (_, borderColor, _) = _getCircleColors();
    return borderColor;
  }
}
