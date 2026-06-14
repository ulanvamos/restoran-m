import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../domain/restaurant_model.dart';
import 'restaurant_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

final searchProvider = FutureProvider.autoDispose.family<List<Restaurant>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];

  final supabase = Supabase.instance.client;
  
  // 1. Direct matches in restaurants table (Name, description, chef)
  final restaurantResponse = await supabase
      .from('restaurants')
      .select()
      .or('name.ilike.%$query%,description.ilike.%$query%,chef_name.ilike.%$query%')
      .eq('is_verified', true)
      .limit(20);

  final List<Restaurant> matchedRestaurants = (restaurantResponse as List)
      .map((json) => Restaurant.fromJson(json))
      .toList();

  // 2. Search in menu_items (Name, description, category) to find restaurants serving that food
  final menuResponse = await supabase
      .from('menu_items')
      .select('restaurant_id')
      .or('name.ilike.%$query%,description.ilike.%$query%,category.ilike.%$query%')
      .limit(50);

  final Set<String> menuRestaurantIds = (menuResponse as List)
      .map((item) => item['restaurant_id'] as String)
      .toSet();

  // Filter out IDs we already fetched
  final existingIds = matchedRestaurants.map((r) => r.id).toSet();
  final List<String> idsToFetch = menuRestaurantIds.where((id) => !existingIds.contains(id)).toList();

  if (idsToFetch.isNotEmpty) {
    // Fetch remaining restaurants by ID
    final additionalRestaurantsResponse = await supabase
        .from('restaurants')
        .select()
        .filter('id', 'in', idsToFetch)
        .eq('is_verified', true);

    final additionalRestaurants = (additionalRestaurantsResponse as List)
        .map((json) => Restaurant.fromJson(json))
        .toList();

    matchedRestaurants.addAll(additionalRestaurants);
  }

  return matchedRestaurants;
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Restoran, şef veya mutfak ara...',
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
          style: const TextStyle(color: AppColors.primary, fontSize: 16),
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
        ),
      ),
      body: _searchQuery.isEmpty
          ? const Center(
              child: Text(
                'Aradığınız lezzeti bulalım...',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : Consumer(
              builder: (context, ref, child) {
                final searchResults = ref.watch(searchProvider(_searchQuery));

                return searchResults.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (err, stack) => Center(child: Text('Hata: $err', style: const TextStyle(color: Colors.red))),
                  data: (restaurants) {
                    if (restaurants.isEmpty) {
                      return const Center(
                        child: Text(
                          'Sonuç bulunamadı.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: restaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = restaurants[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: CachedNetworkImage(
                                imageUrl: restaurant.coverImageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: AppColors.divider),
                                errorWidget: (context, url, error) => Container(color: AppColors.divider),
                              ),
                            ),
                          ),
                          title: Text(
                            restaurant.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          subtitle: Text(
                            '${restaurant.rating.toStringAsFixed(1)} ★ • ${restaurant.address}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RestaurantDetailScreen(restaurant: restaurant),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
