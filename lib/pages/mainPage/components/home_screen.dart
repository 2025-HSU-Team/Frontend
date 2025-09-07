import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    // NOTE: This widget returns only the main content.
    // Header and Bottom navigations are provided by MainPage.
    return _buildMainContent();
  }

  Widget _buildMainContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 로딩 스피너 (진행률 표시기)
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: 0.25, // 25% 진행
              strokeWidth: 8,
              backgroundColor: Colors.blue[100],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            '소리를 분석하고 있습니다...',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
