class Review {
  final String id;
  final String? userId;
  final String? restaurantId;
  final int rating;
  final int ambianceRating;
  final int foodRating;
  final String comment;
  final DateTime createdAt;
  final String? reviewerName;
  final String? reviewerAvatar;

  Review({
    required this.id,
    this.userId,
    this.restaurantId,
    required this.rating,
    required this.ambianceRating,
    required this.foodRating,
    required this.comment,
    required this.createdAt,
    this.reviewerName,
    this.reviewerAvatar,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final userData = json['users'] as Map<String, dynamic>?;
    return Review(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      restaurantId: json['restaurant_id'] as String?,
      rating: json['rating'] as int? ?? 5,
      ambianceRating: json['ambiance_rating'] as int? ?? 5,
      foodRating: json['food_rating'] as int? ?? 5,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewerName: userData?['full_name'] as String?,
      reviewerAvatar: userData?['avatar_url'] as String?,
    );
  }
}
