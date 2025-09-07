import 'package:flutter/material.dart';

class HeaderNavigation extends StatelessWidget {
  final int selectedCategoryIndex;
  final Function(int) onCategoryChanged;
  final List<String> categories;

  const HeaderNavigation({
    super.key,
    required this.selectedCategoryIndex,
    required this.onCategoryChanged,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 앱 아이콘
          _buildLogo(),

          const SizedBox(height: 20),

          // 카테고리 탭
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: categories.asMap().entries.map((entry) {
                int index = entry.key;
                String category = entry.value;
                bool isSelected = index == selectedCategoryIndex;

                return GestureDetector(
                  onTap: () => onCategoryChanged(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[600],
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return FutureBuilder<AssetBundleImageKey>(
      future: const AssetImage('assets/images/Icon.png').obtainKey(const ImageConfiguration()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return Image.asset(
            'assets/images/Icon.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          );
        }
        // Fallback: simple icon if asset not found or while loading
        return Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.hearing, color: Colors.blue, size: 40),
        );
      },
    );
  }
}
