import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/restaurant_model.dart';
import '../domain/menu_item_model.dart';
import '../domain/review_model.dart';
import '../domain/table_model.dart';

import 'package:latlong2/latlong.dart';

final restaurantsProvider = FutureProvider<List<Restaurant>>((ref) async {
  final mode = ref.watch(locationFilterModeProvider);
  final selectedCity = ref.watch(selectedCityProvider);

  var query = Supabase.instance.client
      .from('restaurants')
      .select()
      .eq('is_verified', true)
      .eq('is_banned', false);

  if (mode == LocationFilterMode.selectedLocation) {
    query = query.ilike('address', '%$selectedCity%');
  }

  final response = await query;
      
  List<Restaurant> restaurants = (response as List).map((json) => Restaurant.fromJson(json)).toList();

  if (mode == LocationFilterMode.myLocation) {
    const userLoc = LatLng(40.2220, 28.9350); // Mevcut konum (Mock)
    const distance = Distance();
    
    restaurants = restaurants.where((r) {
      final km = distance.as(LengthUnit.Kilometer, userLoc, LatLng(r.latitude, r.longitude));
      return km <= 50; // 50 km yarıçap
    }).toList();
  }

  restaurants.sort((a, b) {
    if (a.isSponsored && !b.isSponsored) return -1;
    if (!a.isSponsored && b.isSponsored) return 1;
    return b.rating.compareTo(a.rating);
  });

  return restaurants;
});

final featuredRestaurantsProvider = FutureProvider<List<Restaurant>>((ref) async {
  final restaurants = await ref.watch(restaurantsProvider.future);
  
  // Anamnez simülasyonu: Sponsorlu olanlar ve puanı 4.0 üstü olanlar öne çıkanlara girer
  final featured = restaurants.where((r) => r.isSponsored || r.rating >= 4.0).toList();
  
  featured.sort((a, b) {
    if (a.isSponsored && !b.isSponsored) return -1;
    if (!a.isSponsored && b.isSponsored) return 1;
    return b.rating.compareTo(a.rating);
  });
  
  return featured;
});

final alternativeRestaurantsProvider = FutureProvider<List<Restaurant>>((ref) async {
  final mode = ref.watch(locationFilterModeProvider);
  final selectedCity = ref.watch(selectedCityProvider);
  
  if (mode != LocationFilterMode.selectedLocation) return [];

  final response = await Supabase.instance.client
      .from('restaurants')
      .select()
      .eq('is_verified', true)
      .eq('is_banned', false);

  List<Restaurant> allRestaurants = (response as List).map((json) => Restaurant.fromJson(json)).toList();
  
  final alternatives = allRestaurants.where((r) {
    final address = (r.address).toLowerCase();
    final city = (r.city ?? '').toLowerCase();
    final search = selectedCity.toLowerCase();
    return !address.contains(search) && !city.contains(search);
  }).toList();

  alternatives.sort((a, b) => b.rating.compareTo(a.rating));
  return alternatives.take(5).toList();
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
      
  final list = (response as List).map((json) => ReelData.fromJson(json)).toList();
  list.shuffle();
  return list;
});

final restaurantSpecificReelsProvider = FutureProvider.autoDispose.family<List<ReelData>, String>((ref, restaurantId) async {
  final response = await Supabase.instance.client
      .from('restaurant_reels')
      .select('*')
      .eq('restaurant_id', restaurantId)
      .order('created_at', ascending: false);
      
  return (response as List).map((json) => ReelData.fromJson(json)).toList();
});

enum LocationFilterMode { myLocation, selectedLocation, worldwide }

class LocationFilterNotifier extends Notifier<LocationFilterMode> {
  @override
  LocationFilterMode build() {
    _load();
    return LocationFilterMode.worldwide;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt('locationFilterMode');
    if (modeIndex != null && modeIndex >= 0 && modeIndex < LocationFilterMode.values.length) {
      state = LocationFilterMode.values[modeIndex];
    }
  }

  Future<void> setMode(LocationFilterMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('locationFilterMode', mode.index);
  }
}

final locationFilterModeProvider = NotifierProvider<LocationFilterNotifier, LocationFilterMode>(
  () => LocationFilterNotifier(),
);

class SelectedCityNotifier extends Notifier<String> {
  @override
  String build() {
    _load();
    return 'Bursa';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString('selectedCity');
    if (city != null) {
      state = city;
    }
  }

  Future<void> setCity(String city) async {
    state = city;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCity', city);
  }
}

final selectedCityProvider = NotifierProvider<SelectedCityNotifier, String>(
  () => SelectedCityNotifier(),
);
