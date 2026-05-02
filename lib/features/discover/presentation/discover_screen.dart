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

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsyncValue = ref.watch(restaurantsProvider);

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
                            return const Center(child: Text('Henüz restoran bulunmuyor.'));
                          }
                          
                          // Split mock data into two sections for demonstration
                          final recommended = restaurants.take(2).toList();
                          final featured = restaurants.skip(2).take(2).toList();
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSection(
                                title: 'Sizin için önerilenler',
                                delayMs: 200,
                                restaurants: recommended,
                              ),
                              const SizedBox(height: 48),
                              _buildSection(
                                title: 'Öne çıkan restoranlar',
                                delayMs: 400,
                                restaurants: featured.isNotEmpty ? featured : recommended,
                              ),
                            ],
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
          bottom: BorderSide(color: AppColors.divider.withOpacity(0.5), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          // Search Bar
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: AppColors.divider.withOpacity(0.3)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.textSecondary.withOpacity(0.6), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Restoran, şef veya mutfak ara',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary.withOpacity(0.6),
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
          const SizedBox(width: 16),
          // Notification
          const Icon(Icons.notifications_none, color: AppColors.primary, size: 28),
        ],
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'Bursa, Nilüfer'.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 2.0,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.expand_more, color: AppColors.textSecondary, size: 16),
        ],
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
                child: _buildRestaurantCard(
                  title: restaurant.name,
                  subtitle: restaurant.description,
                  location: restaurant.address,
                  rating: restaurant.rating.toStringAsFixed(1),
                  imageUrl: restaurant.coverImageUrl,
                ),
              ).animate().fade(delay: (delayMs + (index * 100)).ms).slideY(begin: 0.1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantCard({
    required String title,
    required String subtitle,
    required String location,
    required String rating,
    required String imageUrl,
  }) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
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
            imageUrl: imageUrl,
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
                  AppColors.primary.withOpacity(0.2),
                  AppColors.primary.withOpacity(0.9),
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
                        title,
                        style: AppTextStyles.headline.copyWith(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            rating,
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
                  subtitle,
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
                    Text(
                      location.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white60,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
