import 'package:flutter/material.dart';

class ConcertPage extends StatefulWidget {
  const ConcertPage({super.key});

  @override
  State<ConcertPage> createState() => _ConcertPageState();
}

class _ConcertPageState extends State<ConcertPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 원형 그래픽 (가사 표시 영역)
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.blue[200]!,
                width: 2,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  '가사가사가사가사가사가사가사가사',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
