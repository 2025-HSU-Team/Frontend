import 'package:flutter/material.dart';

class ControlButtonsWidget extends StatelessWidget {
  final bool isDetecting;
  final VoidCallback? onManualDetection;
  final VoidCallback? onTestResponse;
  final VoidCallback? onCreateTestFile;

  const ControlButtonsWidget({
    super.key,
    required this.isDetecting,
    this.onManualDetection,
    this.onTestResponse,
    this.onCreateTestFile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: isDetecting ? null : onManualDetection,
              icon: Image.asset(
                'assets/images/redmike.png',
                width: 24,
                height: 24,
                color: Colors.white,
              ),
              label: const Text('수동 소리 탐지'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: onTestResponse,
              icon: Image.asset(
                'assets/images/emergency.png',
                width: 24,
                height: 24,
                color: Colors.white,
              ),
              label: const Text('테스트 응답'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: onCreateTestFile,
          icon: Image.asset(
            'assets/images/bell.png',
            width: 24,
            height: 24,
            color: Colors.white,
          ),
          label: const Text('테스트 오디오 파일 생성'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
