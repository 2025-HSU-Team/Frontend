import 'package:flutter/material.dart';
import 'package:frontend/shared_components/bottom_navigation.dart';
import 'package:frontend/shared_components/header_navigation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0;
  int _selectedCategoryIndex = 0;

  final List<String> _categories = ['일상생활', '콘서트', '연극'];

  void _onCategoryChanged(int index) {
    setState(() {
      _selectedCategoryIndex = index;
    });
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더 네비게이션
            HeaderNavigation(
              selectedCategoryIndex: _selectedCategoryIndex,
              onCategoryChanged: _onCategoryChanged,
              categories: _categories,
            ),

            // 메인 콘텐츠 영역
            Expanded(child: _buildMainContent()),

            // 하단 네비게이션
            BottomNavigation(
              selectedTabIndex: _selectedTabIndex,
              onTabChanged: _onTabChanged,
            ),
          ],
        ),
      ),
    );
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
