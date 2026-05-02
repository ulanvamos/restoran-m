class Restaurant {
  final String id;
  final String name;
  final String description;
  final String address;
  final String coverImageUrl;
  final double rating;
  final double latitude;
  final double longitude;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.coverImageUrl,
    required this.rating,
    required this.latitude,
    required this.longitude,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? '',
      coverImageUrl: json['cover_image_url'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
