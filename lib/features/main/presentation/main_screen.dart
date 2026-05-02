import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../discover/presentation/map_screen.dart';

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
    const Center(child: Text('Reels Screen (Coming Soon)')),
    const Center(child: Text('Bookings Screen (Coming Soon)')),
    const Center(child: Text('Profile Screen (Coming Soon)')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              offset: const Offset(0, -10),
              blurRadius: 30,
            ),
          ],
          border: Border(
            top: BorderSide(
              color: AppColors.divider.withOpacity(0.5),
              width: 1.0,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(icon: Icons.home_filled, index: 0),
                _buildNavItem(icon: Icons.map_outlined, index: 1),
                _buildNavItem(icon: Icons.movie_filter_outlined, index: 2),
                _buildNavItem(icon: Icons.event_available_outlined, index: 3),
                _buildNavItem(icon: Icons.person_outline, index: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index}) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        transform: Matrix4.identity()..scale(isSelected ? 1.0 : 0.9),
        child: Icon(
          icon,
          size: 28,
          color: isSelected ? AppColors.primary : Colors.grey.shade400,
        ),
      ),
    );
  }
}
