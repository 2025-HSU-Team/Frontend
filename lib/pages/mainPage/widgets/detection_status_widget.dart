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
    with SingleTickerProviderStateMixin {
  late AnimationController _textController;
  String _detectionText = '인식중';

  @override
  void initState() {
    super.initState();
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
    _textController.repeat();
    _updateDetectionText();
  }

  void _stopDetectionAnimation() {
    _textController.stop();
    setState(() {
      _detectionText = '자동 탐지 대기 중';
    });
  }

  void _updateDetectionText() {
    final animation = _textController.value;
    String text;
    
    if (animation < 0.33) {
      text = '인식중';
    } else if (animation < 0.66) {
      text = '인식중...';
    } else {
      text = '인식중.....';
    }
    
    if (_detectionText != text) {
      setState(() {
        _detectionText = text;
      });
    }
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isDetecting ? Colors.purple[50] : Colors.blue[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isDetecting ? Colors.purple : Colors.blue,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                widget.isDetecting ? 'assets/images/redmike.png' : 'assets/images/bluemike.png',
                width: 20,
                height: 20,
                color: widget.isDetecting ? Colors.purple : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                _detectionText,
                style: TextStyle(
                  color: widget.isDetecting ? Colors.purple : Colors.blue,
                  fontWeight: FontWeight.w500,
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
