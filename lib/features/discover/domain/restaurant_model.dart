class Restaurant {
  final String id;
  final String name;
  final String description;
  final String address;
  final String coverImageUrl;
  final double rating;
  final double latitude;
  final double longitude;
  final String videoUrl;
  final int cancellationDeadlineHours;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.coverImageUrl,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.videoUrl,
    this.cancellationDeadlineHours = 8,
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
      videoUrl: json['video_url'] as String? ?? '',
      cancellationDeadlineHours: (json['cancellation_deadline_hours'] as num?)?.toInt() ?? 8,
    );
  }
}
