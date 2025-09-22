import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class BackendService {
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;
  BackendService._internal();

  static const String _baseUrl = 'https://13.209.61.41.nip.io';
  String? _accessToken;

  // 콜백 함수들
  Function(Map<String, dynamic>)? onSoundDetected;
  Function(String)? onError;

  // ==================== 초기화 ====================
  
  Future<void> initialize() async {
    await _loadAccessToken();
  }

  Future<void> _loadAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('accessToken');
      print('🔑 액세스 토큰: ${_accessToken ?? "없음"}');
    } catch (e) {
      print('❌ 토큰 로드 실패: $e');
    }
  }

  // ==================== 소리 분석 ====================
  
  Future<void> analyzeSound(String filePath) async {
    if (_accessToken == null) {
      onError?.call('로그인이 필요합니다.');
      return;
    }

    try {
      print('🎯 소리 파일 분석 시작');
      print('📁 전송할 파일: $filePath');
      
      final file = File(filePath);
      if (!await file.exists()) {
        onError?.call('파일이 존재하지 않습니다.');
        return;
      }

      final uri = Uri.parse('$_baseUrl/api/sound/match');
      final request = http.MultipartRequest('POST', uri);
      
      // 헤더 설정
      request.headers['Authorization'] = 'Bearer $_accessToken';
      print('🔐 Authorization 헤더 설정 완료');
      
      // 파일 첨부
      final mimeType = lookupMimeType(filePath) ?? 'audio/wav';
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: MediaType.parse(mimeType),
      ));
      print('📎 파일 첨부 완료: ${p.basename(filePath)}');
      
      // 요청 전송
      print('📤 백엔드로 소리 파일 전송 시작...');
      final response = await request.send();
      final result = await http.Response.fromStream(response);
      
      print('📥 응답 상태 코드: ${result.statusCode}');
      print('📥 응답 본문: ${result.body}');
      
      if (result.statusCode == 200) {
        _handleResponse(result.body);
      } else {
        onError?.call('서버 오류: ${result.statusCode}');
      }
      
    } catch (e) {
      print('❌ 백엔드 요청 실패: $e');
      onError?.call('네트워크 오류: $e');
    }
  }

  // ==================== 응답 처리 ====================
  
  void _handleResponse(String body) {
    try {
      final Map<String, dynamic> json = jsonDecode(body);
      
      if (json['isSuccess'] == true && json['data'] != null) {
        final soundName = json['data']['soundName'] ?? '알 수 없음';
        final confidence = json['data']['confidence'] ?? 0.0;
        
        print('✅ 소리 인식 성공: $soundName (신뢰도: $confidence)');
        
        onSoundDetected?.call({
          'soundName': soundName,
          'confidence': confidence,
          'isSuccess': true,
        });
        
      } else {
        final message = json['message'] ?? '인식 실패';
        print('❌ 소리 인식 실패: $message');
        onError?.call(message);
      }
    } catch (e) {
      print('❌ 응답 파싱 실패: $e');
      onError?.call('응답 파싱 실패: $e');
    }
  }

  // ==================== 테스트 기능 ====================
  
  void simulateTestResponse() {
    print('🧪 테스트 응답 시뮬레이션');
    final testResponse = {
      'soundName': '테스트 소리 (개, 고양이, 아기 울음 등)',
      'confidence': 0.95,
      'isSuccess': true,
    };
    
    onSoundDetected?.call(testResponse);
  }

  // ==================== 상태 확인 ====================
  
  bool get isLoggedIn => _accessToken != null;
  String? get accessToken => _accessToken;
}
