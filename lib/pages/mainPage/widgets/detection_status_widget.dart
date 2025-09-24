import 'package:flutter/material.dart';
import '../models/detection_state.dart';

class DetectionStatusWidget extends StatefulWidget {
  final DetectionState state;
  final double currentDb;
  final bool isDetecting;
  final Color? detectionColor; // 인식중일 때 사용할 랜덤 색상

  const DetectionStatusWidget({
    super.key,
    required this.state,
    required this.currentDb,
    required this.isDetecting,
    this.detectionColor, // 옵셔널 파라미터
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
      _detectionText = '자동 탐지 대기 중';
      _dotCount = 0;
    });
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
