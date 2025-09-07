import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // NOTE: This widget returns only the main content.
    // Header and Bottom navigations are provided by MainPage.
    return _buildMainContent();
  }

  Widget _buildMainContent() {
    return Center(
      child: AnimatedBuilder(
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
                // 3개의 원형 파동을 위상 차이를 두고 반복적으로 확장
                _buildPulseRing((t + 0.0) % 1.0),
                _buildPulseRing((t + 0.33) % 1.0),
                _buildPulseRing((t + 0.66) % 1.0),

                // 중앙 고정 원 (애니메이션과 독립적으로 항상 고정)
                _buildCenterCircle(),

                // 중앙 아이콘 이미지
                _buildCenterIcon(),

                // 상태 텍스트 (선택)
                Positioned(
                  bottom: -60,
                  child: Text(
                    '소리를 분석하고 있습니다...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        },
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
