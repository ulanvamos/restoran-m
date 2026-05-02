import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../domain/restaurant_model.dart';
import 'discover_controller.dart';
import 'restaurant_detail_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  Restaurant? _selectedRestaurant;

  // Bursa, Nilüfer approx coordinates
  final LatLng _initialCenter = const LatLng(40.2220, 28.9350);

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(restaurantsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // The Map
          restaurantsAsync.when(
            data: (restaurants) => FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialCenter,
                initialZoom: 13.0,
                onTap: (_, __) {
                  setState(() {
                    _selectedRestaurant = null;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.luxedine.app',
                  tileProvider: NetworkTileProvider(),
                ),
                // Color filter to make the map look warm/sepia like the design
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    0.9, 0, 0, 0, 15,
                    0, 0.8, 0, 0, 10,
                    0, 0, 0.7, 0, 0,
                    0, 0, 0, 1, 0,
                  ]),
                  child: Container(color: Colors.transparent),
                ),
                MarkerLayer(
                  markers: [
                    // Mock User Location Dot
                    Marker(
                      point: _initialCenter,
                      width: 48,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Restaurant Pins
                    ...restaurants.map((r) => _buildRestaurantMarker(r)).toList(),
                  ],
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(child: Text('Harita yüklenemedi: $e')),
          ),

          // Top App Bar Shell
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopAppBar(),
          ),

          // Bottom Card (Visible if a restaurant is selected)
          if (_selectedRestaurant != null)
            Positioned(
              bottom: 24, // above bottom navigation theoretically (bottom nav is in MainScreen)
              left: 24,
              right: 24,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RestaurantDetailScreen(restaurant: _selectedRestaurant!),
                    ),
                  );
                },
                child: _buildBottomCard(_selectedRestaurant!),
              ),
            ),
        ],
      ),
    );
  }

  Marker _buildRestaurantMarker(Restaurant restaurant) {
    final isSelected = _selectedRestaurant?.id == restaurant.id;
    return Marker(
      point: LatLng(restaurant.latitude, restaurant.longitude),
      width: isSelected ? 60 : 50,
      height: isSelected ? 60 : 50,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRestaurant = restaurant;
          });
          _mapController.move(
            LatLng(restaurant.latitude, restaurant.longitude),
            14.5,
          );
        },
        child: AnimatedScale(
          scale: isSelected ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 0,
                        spreadRadius: 2,
                      ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      restaurant.rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSelected ? 13 : 11,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Marker Tip (Triangle)
              CustomPaint(
                size: Size(isSelected ? 14 : 12, isSelected ? 7 : 6),
                painter: _TrianglePainter(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(color: AppColors.divider.withOpacity(0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.restaurant, color: AppColors.primary),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Keşif Haritası',
                style: AppTextStyles.headline.copyWith(
                  fontSize: 18,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Bursa, Nilüfer'.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Icon(Icons.tune, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildBottomCard(Restaurant restaurant) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 50,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  restaurant.name,
                  style: AppTextStyles.headline.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  restaurant.address.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(
                  restaurant.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
