import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../discover/domain/restaurant_model.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String? phoneNumber;
  final String? avatarUrl;
  final int? age;
  final String? gender;
  final String? bio;
  final String? city;
  final DateTime? birthDate;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.fullName,
    this.phoneNumber,
    this.avatarUrl,
    this.age,
    this.gender,
    this.bio,
    this.city,
    this.birthDate,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      bio: json['bio'] as String?,
      city: json['city'] as String?,
      birthDate: json['birth_date'] != null ? DateTime.parse(json['birth_date'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// Current user profile
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return null;

  final response = await supabase
      .from('users')
      .select()
      .eq('id', userId)
      .single();

  return UserProfile.fromJson(response);
});

// Favorite restaurants
final favoriteRestaurantsProvider = FutureProvider<List<Restaurant>>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];

  final favResponse = await supabase
      .from('favorites')
      .select('restaurant_id')
      .eq('user_id', userId);

  final restaurantIds = (favResponse as List).map((e) => e['restaurant_id'] as String).toList();

  if (restaurantIds.isEmpty) return [];

  final response = await supabase
      .from('restaurants')
      .select()
      .inFilter('id', restaurantIds)
      .eq('is_verified', true)
      .eq('is_banned', false);

  return (response as List).map((json) => Restaurant.fromJson(json)).toList();
});
