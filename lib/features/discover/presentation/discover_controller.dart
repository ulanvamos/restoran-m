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
  final String id;
  final String videoUrl;
  final String restaurantId;
  final String? caption;

  ReelData({
    required this.id,
    required this.videoUrl, 
    required this.restaurantId,
    this.caption,
  });

  factory ReelData.fromJson(Map<String, dynamic> json) {
    return ReelData(
      id: json['id'] as String,
      videoUrl: json['video_url'] as String,
      restaurantId: json['restaurant_id'] as String,
      caption: json['caption'] as String?,
    );
  }
}

final reelsProvider = FutureProvider<List<ReelData>>((ref) async {
  final response = await Supabase.instance.client
      .from('restaurant_reels')
      .select('*')
      .order('created_at', ascending: false);
      
  return (response as List).map((json) => ReelData.fromJson(json)).toList();
});
