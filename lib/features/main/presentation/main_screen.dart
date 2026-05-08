import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../discover/presentation/map_screen.dart';
import '../../discover/presentation/reels_screen.dart';
import '../../bookings/presentation/bookings_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DiscoverScreen(),
    const MapScreen(),
    const ReelsScreen(),
    const BookingsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / 5;
    const circleSize = 56.0;
    final leftPosition = (_currentIndex * itemWidth) + (itemWidth / 2) - (circleSize / 2);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              offset: const Offset(0, -10),
              blurRadius: 30,
            ),
          ],
          border: Border(
            top: BorderSide(
              color: AppColors.divider.withAlpha(120),
              width: 1.0,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 80,
            child: Stack(
              children: [
                // Sliding background circle
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  top: (80 - circleSize) / 2,
                  left: leftPosition,
                  child: Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(70),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                  ),
                ),
                // Icons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(icon: Icons.home_filled, index: 0, width: itemWidth),
                    _buildNavItem(icon: Icons.map_outlined, index: 1, width: itemWidth),
                    _buildNavItem(icon: Icons.movie_filter, index: 2, width: itemWidth),
                    _buildNavItem(icon: Icons.event_available_outlined, index: 3, width: itemWidth),
                    _buildNavItem(icon: Icons.person_outline, index: 4, width: itemWidth),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index, required double width}) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: 80,
        child: Center(
          child: AnimatedScale(
            duration: const Duration(milliseconds: 300),
            scale: isSelected ? 1.15 : 1.0,
            curve: Curves.easeOutBack,
            child: Icon(
              icon,
              size: 26,
              color: isSelected ? AppColors.background : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }
}
