import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onAITap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onAITap,
  });

  @override
  State<CustomBottomNavigationBar> createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Stack(
        children: [
          // Navigation Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Home Tab
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isActive: widget.currentIndex == 0,
                ),

                // Post Tab
                _buildNavItem(
                  index: 1,
                  icon: Icons.add_box_rounded,
                  label: 'Post',
                  isActive: widget.currentIndex == 1,
                ),

                _buildNavItem(
                  index: 2,
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  isActive: widget.currentIndex == 2,
                ),

                // Profile Tab
                _buildNavItem(
                  index: 4,
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: widget.currentIndex == 4,
                ),
              ],
            ),
          ),

          // Floating AI Button (Center)
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.deepPurple.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.deepPurple : Colors.grey.shade600,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? Colors.deepPurple : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
