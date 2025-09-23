import 'package:flutter/material.dart';
import 'components/home_screen.dart';
import 'package:frontend/shared_components/bottom_navigation.dart';
import 'package:frontend/shared_components/header_navigation.dart';
import 'package:frontend/custom/basic_screen.dart';
import 'package:frontend/custom/before_login.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedTabIndex = 1; // 기본적으로 홈 탭 선택
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

  // 탭별 화면 반환
  Widget _getTabScreen(int index) {
    switch (index) {
      case 0: // 내소리 탭
        return const BasicScreen();
      case 1: // 홈 탭
        return const HomeScreen();
      case 2: // 옵션 탭
        return const BeforeLogin(); // 임시로 BeforeLogin 사용
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _getTabScreen(_selectedTabIndex),
            ),
            BottomNavigation(
              selectedTabIndex: _selectedTabIndex,
              onTabChanged: _onTabChanged,
            ),
          ],
        ),
      ),
    );
  }
}
