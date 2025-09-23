import 'package:flutter/material.dart';
import '../models/detection_state.dart';

class DetectionStatusWidget extends StatefulWidget {
  final DetectionState state;
  final double currentDb;
  final bool isDetecting;

  const DetectionStatusWidget({
    super.key,
    required this.state,
    required this.currentDb,
    required this.isDetecting,
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
      children: [
        // 데시벨 표시
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _getStateColor(),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            '${widget.currentDb.toStringAsFixed(1)} dB',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        const SizedBox(height: 20),
        // 상태 표시
        Container(
          width: 180, // 고정 너비
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isDetecting ? Colors.purple[50] : Colors.blue[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isDetecting ? Colors.purple : Colors.blue,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // 중앙 정렬
            children: [
              Image.asset(
                widget.isDetecting ? 'assets/images/redmike.png' : 'assets/images/bluemike.png',
                width: 20,
                height: 20,
                color: widget.isDetecting ? Colors.purple : Colors.blue,
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120, // 고정 너비로 텍스트 영역 제한
                child: Text(
                  _detectionText,
                  textAlign: TextAlign.center, // 텍스트 중앙 정렬
                  style: TextStyle(
                    color: widget.isDetecting ? Colors.purple : Colors.blue,
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
