import 'package:flutter/services.dart';

class VibrationService {
  static final VibrationService _instance = VibrationService._internal();
  factory VibrationService() => _instance;
  VibrationService._internal();

  /// 진동 레벨에 따른 진동 실행
  /// [level] 0-5 사이의 진동 레벨 (0: 진동 없음, 1-5: 반복 진동)
  Future<void> vibrate(int level) async {
    try {
      // 진동 레벨을 0-5 범위로 제한
      int clampedLevel = level.clamp(0, 5);
      
      print('📳 진동 실행: 레벨 $clampedLevel');
      
      // 진동 레벨별 패턴 (더 강한 진동)
      switch (clampedLevel) {
        case 0:
          // 진동 없음
          print('📳 진동 없음');
          break;
        case 1:
          // 2초마다 반복 (7초 동안) - 강한 진동
          await _vibrateForDuration(_strongVibration, const Duration(seconds: 7), const Duration(seconds: 2));
          break;
        case 2:
          // 1초마다 반복 (7초 동안) - 강한 진동
          await _vibrateForDuration(_strongVibration, const Duration(seconds: 7), const Duration(seconds: 1));
          break;
        case 3:
          // 0.5초마다 반복 (7초 동안) - 강한 진동
          await _vibrateForDuration(_strongVibration, const Duration(seconds: 7), const Duration(milliseconds: 500));
          break;
        case 4:
          // 0.3초마다 반복 (7초 동안) - 강한 진동
          await _vibrateForDuration(_strongVibration, const Duration(seconds: 7), const Duration(milliseconds: 300));
          break;
        case 5:
          // 0.1초마다 반복 (7초 동안) - 강한 진동
          await _vibrateForDuration(_strongVibration, const Duration(seconds: 7), const Duration(milliseconds: 100));
          break;
        default:
          // 기본값: 1초마다 반복
          await _vibrateForDuration(_strongVibration, const Duration(seconds: 7), const Duration(seconds: 1));
      }
      
    } catch (e) {
      print('📳 진동 실행 오류: $e');
    }
  }

  /// 강한 진동 실행 (여러 진동을 동시에 실행)
  void _strongVibration() {
    // 여러 진동을 연속으로 실행하여 강한 진동 효과
    HapticFeedback.heavyImpact();
    HapticFeedback.selectionClick();
    HapticFeedback.heavyImpact();
  }

  /// 지정된 시간 동안 주기적으로 진동 실행
  /// [vibrationFunction] 진동 함수 (HapticFeedback.xxx)
  /// [totalDuration] 총 진동 지속 시간
  /// [interval] 진동 간격
  Future<void> _vibrateForDuration(Function vibrationFunction, Duration totalDuration, Duration interval) async {
    final startTime = DateTime.now();
    final endTime = startTime.add(totalDuration);
    
    print('📳 진동 패턴 시작: ${interval.inMilliseconds}ms 간격으로 ${totalDuration.inSeconds}초 동안');
    
    // 첫 번째 진동 즉시 실행
    vibrationFunction();
    
    // 주기적으로 진동 실행
    while (DateTime.now().isBefore(endTime)) {
      await Future.delayed(interval);
      
      // 아직 시간이 남아있으면 진동 실행
      if (DateTime.now().isBefore(endTime)) {
        vibrationFunction();
      }
    }
    
    print('📳 진동 패턴 완료');
  }

  /// 진동 기능 지원 여부 확인 (항상 true 반환 - Flutter 기본 기능)
  Future<bool> hasVibrator() async {
    return true; // Flutter의 HapticFeedback은 대부분의 기기에서 지원됨
  }

  /// 진동 중지 (HapticFeedback은 자동으로 중지됨)
  Future<void> cancel() async {
    try {
      print('📳 진동 중지 (자동)');
    } catch (e) {
      print('📳 진동 중지 오류: $e');
    }
  }
}
