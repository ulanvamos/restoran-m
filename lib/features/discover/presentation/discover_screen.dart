import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../domain/restaurant_model.dart';
import 'discover_controller.dart';
import 'restaurant_detail_screen.dart';
import '../../../core/widgets/favorite_button.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsyncValue = ref.watch(restaurantsProvider);
    final featuredAsync = ref.watch(featuredRestaurantsProvider);
    final alternativeAsync = ref.watch(alternativeRestaurantsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.refresh(restaurantsProvider.future),
                color: AppColors.primary,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.only(top: 24, bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLocationSelector().animate().fade(delay: 100.ms).slideX(begin: -0.1),
                      const SizedBox(height: 40),
                      
                      restaurantsAsyncValue.when(
                        data: (restaurants) {
                          if (restaurants.isEmpty) {
                            return alternativeAsync.when(
                              data: (alts) {
                                if (alts.isEmpty) {
                                  return const Center(child: Text('Henüz restoran bulunmuyor.'));
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.location_off, size: 48, color: AppColors.textSecondary),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Üzgünüm, şu anda şehrinizde herhangi bir anlaşmalı restoranımız yoktur. Ancak, yakın şehirlerdeki şu restoranları deneyebilirsiniz:',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: AppColors.textSecondary,
                                              fontSize: 14,
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _buildVerticalSection(
                                      title: 'Diğer Şehirlerdeki Restoranlar',
                                      delayMs: 200,
                                      restaurants: alts,
                                    ),
                                  ],
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                              error: (err, stack) => Center(child: Text('Alternative error: $err')),
                            );
                          }
                          
                          return featuredAsync.when(
                            data: (featured) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (featured.isNotEmpty)
                                    _buildSection(
                                      title: 'Öne çıkan restoranlar',
                                      delayMs: 200,
                                      restaurants: featured,
                                    ),
                                  if (featured.isNotEmpty) const SizedBox(height: 48),
                                  _buildVerticalSection(
                                    title: 'Tüm Restoranlar',
                                    delayMs: 400,
                                    restaurants: restaurants,
                                  ),
                                ],
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                            error: (error, stack) => Center(child: Text('Hata oluştu: $error', style: const TextStyle(color: Colors.red))),
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        ),
                        error: (error, stack) => Center(
                          child: Text('Hata oluştu: $error', style: const TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.5), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Logo
          GestureDetector(
            onTap: () {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                );
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          // Search Bar
          Expanded(
            child: GestureDetector(
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
                        style: GoogleFonts.inter(
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
          ),
          const SizedBox(width: 8),
          // Notification
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.primary, size: 28),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
            },
          ),
        ],
      ),
    );
  }

  void _showCitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  'Konum Seç',
                  style: AppTextStyles.headline.copyWith(fontSize: 20),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.my_location, color: AppColors.primary),
                title: const Text('Mevcut Konumum', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                onTap: () {
                  ref.read(locationFilterModeProvider.notifier).setMode(LocationFilterMode.myLocation);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.public, color: AppColors.primary),
                title: const Text('Tümü', style: TextStyle(color: AppColors.primary)),
                onTap: () {
                  ref.read(locationFilterModeProvider.notifier).setMode(LocationFilterMode.worldwide);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.location_city, color: AppColors.primary),
                title: const Text('Şehir Seç...', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
                onTap: () {
                  Navigator.pop(context); // Close current sheet
                  _showFullCitySelector(); // Open the 81 cities sheet
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const List<String> _citiesOfTurkey = [
    'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Amasya', 'Ankara', 'Antalya', 'Artvin', 'Aydın', 'Balıkesir',
    'Bilecik', 'Bingöl', 'Bitlis', 'Bolu', 'Burdur', 'Bursa', 'Çanakkale', 'Çankırı', 'Çorum', 'Denizli',
    'Diyarbakır', 'Edirne', 'Elazığ', 'Erzincan', 'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun', 'Gümüşhane', 'Hakkari',
    'Hatay', 'Isparta', 'Mersin', 'İstanbul', 'İzmir', 'Kars', 'Kastamonu', 'Kayseri', 'Kırklareli', 'Kırşehir',
    'Kocaeli', 'Konya', 'Kütahya', 'Malatya', 'Manisa', 'Kahramanmaraş', 'Mardin', 'Muğla', 'Muş', 'Nevşehir',
    'Niğde', 'Ordu', 'Rize', 'Sakarya', 'Samsun', 'Siirt', 'Sinop', 'Sivas', 'Tekirdağ', 'Tokat',
    'Trabzon', 'Tunceli', 'Şanlıurfa', 'Uşak', 'Van', 'Yozgat', 'Zonguldak', 'Aksaray', 'Bayburt', 'Karaman',
    'Kırıkkale', 'Batman', 'Şırnak', 'Bartın', 'Ardahan', 'Iğdır', 'Yalova', 'Karabük', 'Kilis', 'Osmaniye',
    'Düzce'
  ];

  void _showFullCitySelector() {
    final sortedCities = List<String>.from(_citiesOfTurkey)..sort();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String searchQuery = '';

        String normalizeTurkish(String text) {
          return text
              .replaceAll('İ', 'i')
              .replaceAll('I', 'ı')
              .replaceAll('Ş', 'ş')
              .replaceAll('Ç', 'ç')
              .replaceAll('Ğ', 'ğ')
              .replaceAll('Ü', 'ü')
              .replaceAll('Ö', 'ö')
              .toLowerCase();
        }
        
        return StatefulBuilder(
          builder: (context, setState) {
            final filteredCities = sortedCities
                .where((c) => normalizeTurkish(c).contains(normalizeTurkish(searchQuery)))
                .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Text(
                          'Şehir Seç',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Şehir ara...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9999),
                          borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9999),
                          borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9999),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: filteredCities.length,
                      itemBuilder: (context, index) {
                        final city = filteredCities[index];
                        return ListTile(
                          title: Text(city),
                          onTap: () {
                            ref.read(locationFilterModeProvider.notifier).setMode(LocationFilterMode.selectedLocation);
                            ref.read(selectedCityProvider.notifier).setCity(city);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLocationSelector() {
    final mode = ref.watch(locationFilterModeProvider);
    final selectedCity = ref.watch(selectedCityProvider);
    
    String displayText = 'TÜMÜ';
    if (mode == LocationFilterMode.myLocation) {
      displayText = 'MEVCUT KONUMUM';
    } else if (mode == LocationFilterMode.selectedLocation) {
      displayText = selectedCity.toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: _showCitySelector,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              displayText,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: 2.0,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.primary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Restaurant> restaurants,
    required int delayMs,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.headline.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const Icon(Icons.arrow_forward, color: AppColors.primary),
            ],
          ),
        ).animate().fade(delay: delayMs.ms).slideX(begin: 0.1),
        const SizedBox(height: 24),
        SizedBox(
          height: 380, // Aspect ratio roughly 4/5 for width 300
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: restaurants.length,
            separatorBuilder: (context, index) => const SizedBox(width: 24),
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RestaurantDetailScreen(restaurant: restaurant),
                    ),
                  );
                },
                child: _buildRestaurantCard(restaurant),
              ).animate().fade(delay: (delayMs + (index * 100)).ms).slideY(begin: 0.1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalSection({
    required String title,
    required List<Restaurant> restaurants,
    required int delayMs,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            title,
            style: AppTextStyles.headline.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ).animate().fade(delay: delayMs.ms).slideX(begin: 0.1),
        const SizedBox(height: 16),
        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: restaurants.length,
          itemBuilder: (context, index) {
            final restaurant = restaurants[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RestaurantDetailScreen(restaurant: restaurant),
                  ),
                );
              },
              child: _buildVerticalRestaurantCard(restaurant),
            ).animate().fade(delay: (delayMs + (index * 50)).ms).slideY(begin: 0.1);
          },
        ),
      ],
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: restaurant.coverImageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: AppColors.divider),
            errorWidget: (context, url, error) => Container(color: AppColors.divider, child: const Icon(Icons.error)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0.9),
                ],
                stops: const [0.4, 0.7, 1.0],
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        restaurant.name,
                        style: AppTextStyles.headline.copyWith(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  restaurant.description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white60, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        restaurant.address.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white60,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: FavoriteButton(
                restaurantId: restaurant.id,
                color: Colors.white,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
          if (restaurant.isSponsored)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    const Text(
                      'SPONSORLU',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
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

  Widget _buildVerticalRestaurantCard(Restaurant restaurant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Image
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: restaurant.coverImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: AppColors.divider),
                  errorWidget: (context, url, error) => Container(color: AppColors.divider, child: const Icon(Icons.error)),
                ),
                if (restaurant.isSponsored)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 10),
                          const SizedBox(width: 2),
                          const Text(
                            'SPONSORLU',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Right Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: AppTextStyles.headline.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FavoriteButton(
                        restaurantId: restaurant.id,
                        size: 20,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '• Fine Dining',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.textSecondary, size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          restaurant.address,
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '₺₺₺₺',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
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
}
