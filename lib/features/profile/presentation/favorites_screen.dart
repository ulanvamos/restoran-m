import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../discover/domain/restaurant_model.dart';
import '../../discover/presentation/restaurant_detail_screen.dart';
import 'profile_controller.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteRestaurantsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'FAVORİLERİM',
          style: AppTextStyles.headline.copyWith(
            fontSize: 16,
            letterSpacing: 2.0,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: favoritesAsync.when(
        data: (favorites) {
          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 48, color: AppColors.divider),
                  const SizedBox(height: 16),
                  const Text(
                    'Henüz favori restoranınız yok.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final restaurant = favorites[index];
              return _buildFavoriteItem(context, ref, restaurant);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Hata: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildFavoriteItem(BuildContext context, WidgetRef ref, Restaurant restaurant) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurant: restaurant)),
        );
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider.withAlpha(40)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Image
            SizedBox(
              width: 100,
              height: 100,
              child: restaurant.coverImageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: restaurant.coverImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.divider.withAlpha(30)),
                      errorWidget: (_, __, ___) => Container(color: AppColors.divider.withAlpha(30)),
                    )
                  : Container(
                      color: AppColors.divider.withAlpha(30),
                      child: const Icon(Icons.restaurant, color: AppColors.textSecondary),
                    ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      restaurant.name,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant.address,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 12, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Text(
                          restaurant.rating.toStringAsFixed(1),
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Remove favorite button
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                onPressed: () => _removeFavorite(context, ref, restaurant.id),
                icon: const Icon(Icons.favorite, color: Colors.red, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeFavorite(BuildContext context, WidgetRef ref, String restaurantId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Favorilerden Çıkar', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.bold, color: AppColors.primary)),
        content: const Text('Bu restoranı favorilerinizden çıkarmak istiyor musunuz?', style: TextStyle(fontFamily: 'Inter', color: AppColors.primary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çıkar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('restaurant_id', restaurantId);

      ref.invalidate(favoriteRestaurantsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Favorilerden çıkarıldı.'), backgroundColor: Colors.green),
        );
      }
    }
  }
}
