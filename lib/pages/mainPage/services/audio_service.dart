import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioRecorder _detectionRecorder = AudioRecorder();
  StreamSubscription<Amplitude>? _ampSub;
  
  // 상태 관리
  bool _isInitialized = false;
  bool _isDetecting = false;
  bool _isMonitoring = false;
  String? _currentTempPath;
  DateTime? _lastLogTime; // 마지막 로그 출력 시간

  // 콜백 함수들
  Function(double)? onAmplitudeChanged;
  Function(String)? onFileRecorded;
  
  // 상태 getter
  bool get isDetecting => _isDetecting;
  bool get isMonitoring => _isMonitoring;

  // ==================== 초기화 ====================
  
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // 권한 확인
      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) {
        print('❌ 마이크 권한 거부됨');
        return false;
      }

      if (!await _recorder.hasPermission()) {
        print('❌ 오디오 권한 없음');
        return false;
      }

      _isInitialized = true;
      print('✅ AudioService 초기화 완료');
      return true;
    } catch (e) {
      print('❌ AudioService 초기화 실패: $e');
      return false;
    }
  }

  // ==================== 실시간 모니터링 ====================
  
  Future<bool> startRealTimeMonitoring() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      // 데시벨 스트림 구독 (100ms 간격으로 업데이트)
      _ampSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amp) {
        final db = amp.current ?? 0.0;
        
        // 1초에 하나씩만 로그 출력
        final now = DateTime.now();
        if (_lastLogTime == null || now.difference(_lastLogTime!).inSeconds >= 1) {
          if (db != 0.0) {
            print('🎤 실시간 데시벨: ${db.toStringAsFixed(1)} dB');
            _lastLogTime = now;
          }
        }
        
        onAmplitudeChanged?.call(db);
      });

      // 임시 파일 경로 생성
      _currentTempPath = await _createRecordingPath();
      
      // 실시간 스트리밍 시작 (데시벨 측정용)
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 44100, // 원래 코드와 동일
        ),
        path: _currentTempPath!,
      );
      
      _isMonitoring = true;
      print('✅ 실시간 데시벨 측정 시작 완료');
      return true;
    } catch (e) {
      print('❌ 실시간 모니터링 시작 실패: $e');
      return false;
    }
  }

  Future<void> stopRealTimeMonitoring() async {
    try {
      await _recorder.stop();
      _ampSub?.cancel();
      _isMonitoring = false;
      print('🛑 실시간 모니터링 중지 완료');
    } catch (e) {
      print('❌ 실시간 모니터링 중지 실패: $e');
    }
  }

  // ==================== 파일 녹음 ====================
  
  Future<String?> startFileRecording() async {
    if (_isDetecting) return null;

    try {
      _isDetecting = true;
      
      // 실시간 모니터링 중지
      await stopRealTimeMonitoring();
      
      // 탐지용 녹음기 준비 완료
      
      // 파일 경로 설정 (원래 코드처럼)
      final filePath = await _createRecordingPath();
      print('📁 녹음 파일 경로: $filePath');

      // 5초간 파일 녹음 시작 (원래 코드와 동일한 설정)
      await _detectionRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000, // 에뮬레이터 호환성을 위한 낮은 샘플 레이트
        ),
        path: filePath,
      );
      
      print('🎙️ 파일 녹음 시작 완료 (2초간)');
      return filePath;
    } catch (e) {
      print('❌ 파일 녹음 시작 실패: $e');
      _isDetecting = false;
      return null;
    }
  }

  Future<File?> stopFileRecording(String filePath) async {
    try {
      // 탐지용 녹음기 중지
      await _detectionRecorder.stop();
      
      _isDetecting = false;
      
      final file = File(filePath);
      if (await file.exists()) {
        // 파일 크기 분석 (원래 코드처럼)
        final fileSize = await file.length();
        print('📁 녹음 파일 확인: ${file.path}');
        print('📏 실제 파일 크기: $fileSize bytes (${(fileSize / 1024).toStringAsFixed(1)} KB)');
        
        // WAV 파일 구조 분석
        final wavHeaderSize = 44;
        final audioDataSize = fileSize - wavHeaderSize;
        print('📊 WAV 헤더 크기: $wavHeaderSize bytes');
        print('🎵 실제 오디오 데이터 크기: ${audioDataSize} bytes (${(audioDataSize / 1024).toStringAsFixed(1)} KB)');
        
        // 5초 녹음 시 예상 크기 (16kHz, 16bit, mono)
        final expectedSize = 16000 * 2 * 5; // 160,000 bytes
        print('📈 5초 녹음 예상 크기: ${expectedSize} bytes (${(expectedSize / 1024).toStringAsFixed(1)} KB)');
        
        if (audioDataSize < 1000) {
          print('⚠️ 경고: 실제 오디오 데이터가 매우 적습니다. 녹음이 제대로 되지 않았을 수 있습니다.');
        } else {
          print('✅ 파일 확인 완료 - 백엔드 분석 진행');
        }
        
        onFileRecorded?.call(filePath);
        return file;
      } else {
        print('❌ 녹음 파일이 존재하지 않음');
        return null;
      }
    } catch (e) {
      print('❌ 파일 녹음 중지 실패: $e');
      _isDetecting = false;
      return null;
    }
  }

  // ==================== 헬퍼 메서드 ====================
  
  Future<String> _createRecordingPath() async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return p.join(dir.path, 'sound_detection_$timestamp.wav');
  }

  // ==================== 정리 ====================
  
  Future<void> dispose() async {
    try {
      _ampSub?.cancel();
      await _recorder.stop();
      await _recorder.dispose();
      _isInitialized = false;
      _isDetecting = false;
      print('✅ AudioService 정리 완료');
    } catch (e) {
      print('❌ AudioService 정리 실패: $e');
    }
  }

  // ==================== 상태 확인 ====================
  
  bool get isInitialized => _isInitialized;
}
