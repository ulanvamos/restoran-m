import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../discover/domain/restaurant_model.dart';
import '../../discover/domain/menu_item_model.dart';

class ReservationData {
  final String id;
  final String restaurantId;
  final String? userId;
  final DateTime reservationDate;
  final String startTime;
  final String endTime;
  final int guestCount;
  final String status;
  final bool wantsVipTransport;
  final bool wantsPreOrder;
  final String? selectedTableName;
  final DateTime createdAt;
  final Restaurant? restaurant;

  ReservationData({
    required this.id,
    required this.restaurantId,
    this.userId,
    required this.reservationDate,
    required this.startTime,
    required this.endTime,
    required this.guestCount,
    required this.status,
    required this.wantsVipTransport,
    required this.wantsPreOrder,
    this.selectedTableName,
    required this.createdAt,
    this.restaurant,
  });

  factory ReservationData.fromJson(Map<String, dynamic> json, {Restaurant? restaurant}) {
    return ReservationData(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      userId: json['user_id'] as String?,
      reservationDate: DateTime.parse(json['reservation_date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      guestCount: json['guest_count'] as int,
      status: json['status'] as String? ?? 'pending',
      wantsVipTransport: json['wants_vip_transport'] as bool? ?? false,
      wantsPreOrder: json['wants_pre_order'] as bool? ?? false,
      selectedTableName: json['selected_table_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      restaurant: restaurant,
    );
  }

  /// Check if reservation can be cancelled based on restaurant's deadline
  bool canCancel() {
    if (status == 'cancelled' || status == 'completed') return false;
    final deadlineHours = restaurant?.cancellationDeadlineHours ?? 8;
    final startHour = int.tryParse(startTime.split(':')[0]) ?? 0;
    final startMinute = int.tryParse(startTime.split(':')[1]) ?? 0;
    final reservationDateTime = DateTime(
      reservationDate.year,
      reservationDate.month,
      reservationDate.day,
      startHour,
      startMinute,
    );
    final deadline = reservationDateTime.subtract(Duration(hours: deadlineHours));
    return DateTime.now().isBefore(deadline);
  }
}

// Fetch all reservations with restaurant data joined
final userReservationsProvider = FutureProvider<List<ReservationData>>((ref) async {
  final supabase = Supabase.instance.client;

  // Fetch reservations
  final reservationsResponse = await supabase
      .from('reservations')
      .select()
      .order('reservation_date', ascending: false);

  // Fetch all restaurants for joining
  final restaurantsResponse = await supabase
      .from('restaurants')
      .select();

  final restaurants = (restaurantsResponse as List)
      .map((json) => Restaurant.fromJson(json))
      .toList();

  final restaurantsMap = {for (var r in restaurants) r.id: r};

  return (reservationsResponse as List).map((json) {
    final restaurantId = json['restaurant_id'] as String;
    return ReservationData.fromJson(json, restaurant: restaurantsMap[restaurantId]);
  }).toList();
});

// Fetch menu items for a specific restaurant (all categories for pre-order)
final restaurantAllMenusProvider = FutureProvider.family<List<MenuItem>, String>((ref, restaurantId) async {
  final response = await Supabase.instance.client
      .from('menu_items')
      .select()
      .eq('restaurant_id', restaurantId)
      .eq('is_available', true);

  return (response as List).map((json) => MenuItem.fromJson(json)).toList();
});
