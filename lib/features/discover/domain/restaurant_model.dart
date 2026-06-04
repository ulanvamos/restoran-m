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
  final String? chefImageUrl;
  final Map<String, dynamic>? serviceHours;
  final Map<String, dynamic>? facilities;
  final String? phoneNumber;
  final String? email;
  final String? website;
  final String? instagram;
  final String? facebook;
  final String? twitter;

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
    this.chefImageUrl,
    this.serviceHours,
    this.facilities,
    this.phoneNumber,
    this.email,
    this.website,
    this.instagram,
    this.facebook,
    this.twitter,
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
      chefImageUrl: json['chef_image_url'] as String?,
      serviceHours: json['service_hours'] != null ? Map<String, dynamic>.from(json['service_hours'] as Map) : null,
      facilities: json['facilities'] != null ? Map<String, dynamic>.from(json['facilities'] as Map) : null,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      instagram: json['instagram'] as String?,
      facebook: json['facebook'] as String?,
      twitter: json['twitter'] as String?,
    );
  }
}
