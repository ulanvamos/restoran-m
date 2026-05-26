class RestaurantTable {
  final String id;
  final String restaurantId;
  final String tableNumber;
  final int capacity;
  final String section;
  final String status;

  RestaurantTable({
    required this.id,
    required this.restaurantId,
    required this.tableNumber,
    required this.capacity,
    required this.section,
    required this.status,
  });

  factory RestaurantTable.fromJson(Map<String, dynamic> json) {
    return RestaurantTable(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      tableNumber: json['table_number'] as String? ?? '',
      capacity: json['capacity'] as int? ?? 2,
      section: json['section'] as String? ?? 'Bahçe',
      status: json['status'] as String? ?? 'empty',
    );
  }
}
