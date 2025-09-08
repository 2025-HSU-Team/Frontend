import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isSoundDetected = false;
  FlutterSoundRecorder? _recorder;
  StreamSubscription? _recorderSub;
  StreamController<Uint8List>? _audioController;
  static const double _dbThreshold = 60; // dB 임계값

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _audioController = StreamController<Uint8List>();
    _initMic();
  }

  @override
  void dispose() {
    _recorderSub?.cancel();
    _recorder?.closeRecorder();
    _audioController?.close();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initMic() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    await _recorder!.setSubscriptionDuration(const Duration(milliseconds: 200));
    _recorderSub = _recorder!.onProgress?.listen((event) {
      final db = event.decibels ?? 0.0;
      final detected = db > _dbThreshold;
      if (detected != _isSoundDetected) {
        setState(() {
          _isSoundDetected = detected;
          if (_isSoundDetected) {
            _controller.repeat();
          } else {
            _controller.stop();
            _controller.value = 0.0;
          }
        });
      }
    });
    await _recorder!.startRecorder(
      toStream: _audioController!.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 16000,
    );
  }

  @override
  Widget build(BuildContext context) {
    // NOTE: This widget returns only the main content.
    // Header and Bottom navigations are provided by MainPage.
    return _buildMainContent();
  }

  Widget _buildMainContent() {
    return Center(
      child: GestureDetector(
        onTap: () {
          // 임시 토글: 소리 감지 상태 테스트용
          setState(() {
            _isSoundDetected = !_isSoundDetected;
            if (_isSoundDetected) {
              _controller.repeat();
            } else {
              _controller.stop();
              _controller.value = 0.0;
            }
          });
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isSoundDetected
              ? AnimatedBuilder(
                  key: const ValueKey('anim'),
                  animation: _controller,
                  builder: (context, _) {
                    final double t = _controller.value; // 0.0 → 1.0 반복
                    return SizedBox(
                      width: double.infinity,
                      height: 500,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          _buildPulseRing((t + 0.0) % 1.0),
                          _buildPulseRing((t + 0.33) % 1.0),
                          _buildPulseRing((t + 0.66) % 1.0),
                          _buildCenterCircle(),
                          _buildCenterIcon(),
                        ],
                      ),
                    );
                  },
                )
              : SizedBox(
                  key: const ValueKey('idle'),
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    strokeWidth: 8,
                    backgroundColor: Colors.blue[100],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
        ),
      ),
    );
  }

  // progress: 0.0 → 1.0
  Widget _buildPulseRing(double progress) {
    const double baseDiameter = 156.0; // 중앙 고정 원 직경
    final double minScale = 1.0; // 시작을 중앙 원 크기에서
    final double maxScale = 4.0; // 사실상 최대치 제거(컨테이너 한계까지 확장)
    final double scale = minScale + (maxScale - minScale) * progress;
    final double opacity = (1.0 - progress).clamp(0.0, 1.0);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: baseDiameter,
        height: baseDiameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.blue.withOpacity(0.25 * opacity),
            width: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCenterCircle() {
    return Container(
      width: 156,
      height: 156,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.withOpacity(0.12),
      ),
    );
  }

  Widget _buildCenterIcon() {
    const primary = 'assets/blue/cry_blue.png';
    const fallback = 'assets/blue/smile_blue.png';

    return FutureBuilder<AssetBundleImageKey>(
      future: const AssetImage(primary).obtainKey(const ImageConfiguration()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return Image.asset(primary, width: 140, height: 140);
        }
        // primary 미존재 시 대체 이미지 사용
        return Image.asset(
          fallback,
          width: 140,
          height: 140,
          errorBuilder: (_, __, ___) => const Icon(Icons.hearing, size: 80, color: Colors.blue),
        );
      },
    );
  }
}
