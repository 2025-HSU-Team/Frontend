import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

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
      
      // 진동 기능 지원 여부 확인
      bool hasVibrator = await Vibration.hasVibrator() ?? false;
      if (!hasVibrator) {
        print('📳 진동 기능을 지원하지 않는 기기입니다.');
        return;
      }
      
      // 진동 레벨별 세기 (vibration 패키지 사용 - 7초간 지속 진동)
      switch (clampedLevel) {
        case 0:
          // 진동 없음
          print('📳 진동 없음');
          break;
        case 1:
          // 약한 진동 (200ms, amplitude 50) - 7초간 반복
          await _vibrateForDuration(200, 50, const Duration(seconds: 7), const Duration(milliseconds: 800));
          break;
        case 2:
          // 보통 진동 (300ms, amplitude 100) - 7초간 반복
          await _vibrateForDuration(300, 100, const Duration(seconds: 7), const Duration(milliseconds: 600));
          break;
        case 3:
          // 강한 진동 (400ms, amplitude 150) - 7초간 반복
          await _vibrateForDuration(400, 150, const Duration(seconds: 7), const Duration(milliseconds: 500));
          break;
        case 4:
          // 매우 강한 진동 (500ms, amplitude 200) - 7초간 반복
          await _vibrateForDuration(500, 200, const Duration(seconds: 7), const Duration(milliseconds: 400));
          break;
        case 5:
          // 극강 진동 (600ms, amplitude 255) - 7초간 반복
          await _vibrateForDuration(600, 255, const Duration(seconds: 7), const Duration(milliseconds: 300));
          break;
        default:
          // 기본값: 보통 진동
          await _vibrateForDuration(300, 100, const Duration(seconds: 7), const Duration(milliseconds: 600));
      }
      
    } catch (e) {
      print('📳 진동 실행 오류: $e');
      // 오류 발생 시 HapticFeedback으로 대체
      await _fallbackVibrate(level);
    }
  }

  /// 지정된 시간 동안 주기적으로 진동 실행 (vibration 패키지 사용)
  /// [duration] 진동 지속 시간 (밀리초)
  /// [amplitude] 진동 강도 (0-255, 255가 최대)
  /// [totalDuration] 총 진동 지속 시간 (7초)
  /// [interval] 진동 간격
  Future<void> _vibrateForDuration(int duration, int amplitude, Duration totalDuration, Duration interval) async {
    final startTime = DateTime.now();
    final endTime = startTime.add(totalDuration);
    
    print('📳 진동 패턴 시작: ${duration}ms, 강도 ${amplitude}, ${interval.inMilliseconds}ms 간격으로 ${totalDuration.inSeconds}초 동안');
    
    // 첫 번째 진동 즉시 실행
    await Vibration.vibrate(duration: duration, amplitude: amplitude);
    
    // 주기적으로 진동 실행
    while (DateTime.now().isBefore(endTime)) {
      await Future.delayed(interval);
      
      // 아직 시간이 남아있으면 진동 실행
      if (DateTime.now().isBefore(endTime)) {
        await Vibration.vibrate(duration: duration, amplitude: amplitude);
      }
    }
    
    print('📳 진동 패턴 완료');
  }

  /// HapticFeedback 대체 진동 (오류 발생 시 사용)
  Future<void> _fallbackVibrate(int level) async {
    print('📳 HapticFeedback 대체 진동 실행: 레벨 $level');
    
    switch (level) {
      case 0:
        break;
      case 1:
        HapticFeedback.mediumImpact();
        break;
      case 2:
        HapticFeedback.heavyImpact();
        break;
      case 3:
        HapticFeedback.heavyImpact();
        break;
      case 4:
        HapticFeedback.heavyImpact();
        break;
      case 5:
        HapticFeedback.heavyImpact();
        break;
      default:
        HapticFeedback.mediumImpact();
    }
  }

  /// 진동 기능 지원 여부 확인 (vibration 패키지 사용)
  Future<bool> hasVibrator() async {
    return await Vibration.hasVibrator() ?? false;
  }

  /// 진동 취소
  Future<void> cancel() async {
    try {
      await Vibration.cancel();
      print('📳 진동 취소 완료');
    } catch (e) {
      print('📳 진동 취소 오류: $e');
    }
  }

}
