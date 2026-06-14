import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../domain/restaurant_model.dart';
import 'discover_controller.dart';
import 'restaurant_detail_screen.dart';
import 'search_screen.dart';

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
                              color: Colors.blue.withValues(alpha: 0.2),
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
                                  color: Colors.blue.withValues(alpha: 0.5),
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
                        color: Colors.white.withValues(alpha: 0.5),
                        blurRadius: 0,
                        spreadRadius: 2,
                      ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
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
    final selectedCity = ref.watch(selectedCityProvider);
    final mode = ref.watch(locationFilterModeProvider);
    
    String displayText = 'TÜMÜ';
    if (mode == LocationFilterMode.myLocation) {
      displayText = 'MEVCUT KONUMUM';
    } else if (mode == LocationFilterMode.selectedLocation) {
      displayText = selectedCity.toUpperCase();
    }

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      displayText,
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
              ),
              IconButton(
                icon: const Icon(Icons.tune, color: AppColors.primary),
                onPressed: () {
                  _showFilterDialog();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search Bar
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen()));
            },
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: AppColors.divider.withValues(alpha: 0.3)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Restoran, şef veya mutfak ara',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                        fontSize: 12,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Harita Filtreleri',
                    style: AppTextStyles.headline.copyWith(fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: const Text('En Yüksek Puanlılar'),
                trailing: Switch(
                  value: true,
                  onChanged: (val) {},
                  activeColor: AppColors.primary,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.location_on, color: AppColors.primary),
                title: const Text('Şu An Açık Olanlar'),
                trailing: Switch(
                  value: false,
                  onChanged: (val) {},
                  activeColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Uygula', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCard(Restaurant restaurant) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
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
