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
  final String? chefName;
  final String? chefDetails;
  final Map<String, dynamic>? serviceHours;
  final Map<String, dynamic>? facilities;

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
    this.chefName,
    this.chefDetails,
    this.serviceHours,
    this.facilities,
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
      chefName: json['chef_name'] as String?,
      chefDetails: json['chef_details'] as String?,
      serviceHours: json['service_hours'] != null ? Map<String, dynamic>.from(json['service_hours'] as Map) : null,
      facilities: json['facilities'] != null ? Map<String, dynamic>.from(json['facilities'] as Map) : null,
    );
  }
}
