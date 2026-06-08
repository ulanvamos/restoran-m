import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../domain/restaurant_model.dart';
import 'discover_controller.dart';
import 'restaurant_detail_screen.dart';

enum LocationFilterMode { myLocation, selectedLocation, worldwide }

class LocationFilterNotifier extends Notifier<LocationFilterMode> {
  @override
  LocationFilterMode build() => LocationFilterMode.worldwide;
  void setMode(LocationFilterMode mode) => state = mode;
}

final locationFilterModeProvider = NotifierProvider<LocationFilterNotifier, LocationFilterMode>(
  () => LocationFilterNotifier(),
);

class SelectedCityNotifier extends Notifier<String> {
  @override
  String build() => 'Bursa';
  void setCity(String city) => state = city;
}

final selectedCityProvider = NotifierProvider<SelectedCityNotifier, String>(
  () => SelectedCityNotifier(),
);

class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reelsAsync = ref.watch(reelsProvider);
    final restaurantsAsync = ref.watch(restaurantsProvider);
    final filterMode = ref.watch(locationFilterModeProvider);
    final selectedCity = ref.watch(selectedCityProvider);
    const myLocationCity = 'Bursa'; // Varsayılan mock konum

    return Scaffold(
      backgroundColor: Colors.black,
      body: reelsAsync.when(
        data: (reels) {
          if (reels.isEmpty) {
            return const Center(
              child: Text('Henüz video bulunmuyor', style: TextStyle(color: Colors.white)),
            );
          }

          return restaurantsAsync.when(
            data: (restaurants) {
              List<ReelData> filteredReels = [];
              for (var reel in reels) {
                final restaurant = restaurants.firstWhere(
                  (r) => r.id == reel.restaurantId,
                  orElse: () => Restaurant(
                    id: reel.restaurantId,
                    name: 'Bilinmeyen Restoran',
                    description: '',
                    address: '',
                    coverImageUrl: '',
                    rating: 0,
                    latitude: 0,
                    longitude: 0,
                    videoUrl: '',
                  ),
                );

                if (restaurant.name == 'Bilinmeyen Restoran') continue;

                bool matches = false;
                if (filterMode == LocationFilterMode.worldwide) {
                  matches = true;
                } else if (filterMode == LocationFilterMode.myLocation) {
                  matches = restaurant.address.toLowerCase().contains(myLocationCity.toLowerCase());
                } else if (filterMode == LocationFilterMode.selectedLocation) {
                  matches = restaurant.address.toLowerCase().contains(selectedCity.toLowerCase());
                }

                if (matches) {
                  filteredReels.add(reel);
                }
              }

              if (filteredReels.isEmpty) {
                return Stack(
                  children: [
                    const Center(
                      child: Text('Bu konumda henüz video bulunmuyor', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 24,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildLocationSelector(context, ref, filterMode, selectedCity),
                      ),
                    ),
                  ],
                );
              }

              return Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: filteredReels.length,
                    itemBuilder: (context, index) {
                      final reel = filteredReels[index];
                      final restaurant = restaurants.firstWhere((r) => r.id == reel.restaurantId);
                      return ReelItem(restaurant: restaurant, reel: reel);
                    },
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _buildLocationSelector(context, ref, filterMode, selectedCity),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, _) => Center(child: Text('Hata: $err', style: const TextStyle(color: Colors.red))),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Hata: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildLocationSelector(BuildContext context, WidgetRef ref, LocationFilterMode mode, String city) {
    String displayText = 'Worldwide';
    if (mode == LocationFilterMode.myLocation) displayText = 'Konumum';
    else if (mode == LocationFilterMode.selectedLocation) displayText = city;

    return GestureDetector(
      onTap: () => _showLocationOptions(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(120),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: AppColors.background, size: 16),
            const SizedBox(width: 6),
            Text(
              displayText,
              style: const TextStyle(color: AppColors.background, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.background, size: 18),
          ],
        ),
      ),
    );
  }

  void _showLocationOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Konum Seçimi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.my_location, color: AppColors.primary),
                title: const Text('Konumum', style: TextStyle(color: AppColors.primary)),
                onTap: () {
                  ref.read(locationFilterModeProvider.notifier).setMode(LocationFilterMode.myLocation);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.public, color: AppColors.primary),
                title: const Text('Worldwide (Tüm Dünya)', style: TextStyle(color: AppColors.primary)),
                onTap: () {
                  ref.read(locationFilterModeProvider.notifier).setMode(LocationFilterMode.worldwide);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.map, color: AppColors.primary),
                title: const Text('Farklı Bir Konum Seç', style: TextStyle(color: AppColors.primary)),
                onTap: () {
                  Navigator.pop(context);
                  _showCitySelector(context, ref);
                },
              ),
            ],
          ),
        );
      }
    );
  }

  void _showCitySelector(BuildContext context, WidgetRef ref) {
    final cities = ['İstanbul', 'Ankara', 'İzmir', 'Antalya', 'Bursa', 'Bodrum', 'Eskişehir', 'Çanakkale'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Şehir Seçin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 16),
              ...cities.map((city) => ListTile(
                title: Text(city, style: const TextStyle(color: AppColors.primary)),
                onTap: () {
                  ref.read(selectedCityProvider.notifier).setCity(city);
                  ref.read(locationFilterModeProvider.notifier).setMode(LocationFilterMode.selectedLocation);
                  Navigator.pop(context);
                },
              )).toList(),
            ],
          ),
        );
      }
    );
  }
}

class ReelItem extends StatefulWidget {
  final Restaurant restaurant;
  final ReelData reel;

  const ReelItem({super.key, required this.restaurant, required this.reel});

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  late VideoPlayerController _videoController;
  bool _isPlaying = true;
  bool _isError = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.reel.videoUrl));
    try {
      await _videoController.initialize();
      _videoController.setLooping(true);
      _videoController.play();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!mounted || !_videoController.value.isInitialized) return;
    setState(() {
      if (_isPlaying) {
        _videoController.pause();
      } else {
        _videoController.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Video or Image fallback
          if (_videoController.value.isInitialized && !_isError)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            CachedNetworkImage(
              imageUrl: widget.restaurant.coverImageUrl,
              fit: BoxFit.cover,
              color: Colors.black.withAlpha(50),
              colorBlendMode: BlendMode.darken,
            ),

          // Gradients
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withAlpha(150),
                  Colors.transparent,
                  AppColors.primary.withAlpha(220),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // Top Nav Shell
          Positioned(
            top: MediaQuery.of(context).padding.top + 24,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background.withAlpha(50)),
                  ),
                  child: const Center(
                    child: Icon(Icons.restaurant, color: AppColors.background, size: 20),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border, 
                    color: _isFavorite ? Colors.red : AppColors.background, 
                    size: 28
                  ),
                  onPressed: () {
                    setState(() {
                      _isFavorite = !_isFavorite;
                    });
                  },
                ),
              ],
            ),
          ),

          // Main Info Area
          Positioned(
            bottom: 120, // To give space for bottom navigation bar
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.background, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          widget.restaurant.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            color: AppColors.background,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Text('•', style: TextStyle(color: AppColors.background.withAlpha(100), fontSize: 12)),
                    const SizedBox(width: 8),
                    Text(
                      widget.restaurant.address.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: AppColors.background.withAlpha(200),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.restaurant.name,
                  style: AppTextStyles.headline.copyWith(
                    color: AppColors.background,
                    fontSize: 32,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  (widget.reel.caption != null && widget.reel.caption!.isNotEmpty)
                      ? widget.reel.caption!
                      : (widget.restaurant.description.isNotEmpty 
                          ? widget.restaurant.description 
                          : 'Modern Anadolu mutfağı ve zamansız bir gastronomi deneyimi.'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: AppColors.background.withAlpha(150),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RestaurantDetailScreen(restaurant: widget.restaurant),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.background.withAlpha(50),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'DETAYLARI GÖR',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.5,
                            color: AppColors.background,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.arrow_forward, color: AppColors.background, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Play/pause indicator
          if (!_isPlaying)
            const Center(
              child: Icon(Icons.play_arrow, color: Colors.white54, size: 64),
            ),
        ],
      ),
    );
  }
}
