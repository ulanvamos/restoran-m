import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/restaurant_model.dart';
import '../domain/menu_item_model.dart';
import '../domain/review_model.dart';
import '../domain/table_model.dart';

final restaurantsProvider = FutureProvider<List<Restaurant>>((ref) async {
  final response = await Supabase.instance.client
      .from('restaurants')
      .select()
      .order('rating', ascending: false);
      
  return (response as List).map((json) => Restaurant.fromJson(json)).toList();
});

final restaurantMenusProvider = FutureProvider.autoDispose.family<List<MenuItem>, String>((ref, restaurantId) async {
  final response = await Supabase.instance.client
      .from('menu_items')
      .select()
      .eq('restaurant_id', restaurantId)
      .eq('is_available', true);
      
  return (response as List).map((json) => MenuItem.fromJson(json)).toList();
});

final restaurantReviewsProvider = FutureProvider.autoDispose.family<List<Review>, String>((ref, restaurantId) async {
  final response = await Supabase.instance.client
      .from('reviews')
      .select('*, users(full_name, avatar_url)')
      .eq('restaurant_id', restaurantId)
      .order('created_at', ascending: false);
      
  return (response as List).map((json) => Review.fromJson(json)).toList();
});

final restaurantTablesProvider = FutureProvider.autoDispose.family<List<RestaurantTable>, String>((ref, restaurantId) async {
  final response = await Supabase.instance.client
      .from('tables')
      .select()
      .eq('restaurant_id', restaurantId);
      
  final list = (response as List).map((json) => RestaurantTable.fromJson(json)).toList();
  // Sort table numbers numerically if possible
  list.sort((a, b) {
    final aNum = int.tryParse(a.tableNumber) ?? 999;
    final bNum = int.tryParse(b.tableNumber) ?? 999;
    return aNum.compareTo(bNum);
  });
  return list;
});

class ReelData {
  final String videoUrl;
  final String restaurantId;
  ReelData({required this.videoUrl, required this.restaurantId});
}

final reelsProvider = FutureProvider<List<ReelData>>((ref) async {
  final List<FileObject> files = await Supabase.instance.client
      .storage
      .from('restaurant-videos')
      .list();
      
  final List<ReelData> reels = [];
  for (final file in files) {
    if (file.name.endsWith('.mp4')) {
      final restaurantId = file.name.replaceAll('.mp4', '');
      final videoUrl = Supabase.instance.client
          .storage
          .from('restaurant-videos')
          .getPublicUrl(file.name);
          
      reels.add(ReelData(
        videoUrl: videoUrl,
        restaurantId: restaurantId,
      ));
    }
  }
  return reels;
});
