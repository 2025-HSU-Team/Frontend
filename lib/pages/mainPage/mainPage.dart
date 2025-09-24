import 'package:flutter/material.dart';
import 'components/home_screen.dart';
import 'package:frontend/shared_components/bottom_navigation.dart';
import 'package:frontend/shared_components/header_navigation.dart';
import 'package:frontend/custom/basic_screen.dart';
import 'package:frontend/custom/before_login.dart';
import 'package:frontend/alarm/alarm_set.dart';

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
        return const AlarmSetScreen();
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
            // 옵션 탭(2번)과 내소리 탭(0번)일 때는 하단바 숨김
            if (_selectedTabIndex != 2 && _selectedTabIndex != 0)
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
