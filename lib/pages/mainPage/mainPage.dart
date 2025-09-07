import 'package:flutter/material.dart';
import 'components/home_screen.dart';
import 'package:frontend/shared_components/bottom_navigation.dart';
import 'package:frontend/shared_components/header_navigation.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
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
            HeaderNavigation(
              selectedCategoryIndex: _selectedCategoryIndex,
              onCategoryChanged: _onCategoryChanged,
              categories: _categories,
            ),
            const Expanded(child: HomeScreen()),
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
