class User {
  final int id;
  final String name;
  final String email;
  final String? profilePhoto;
  final DateTime? createdAt;
  final bool isFollowing;
  final int? followersCount;
  final int? followingCount;
  final int reviewCount; // Add review count
  final List<Review>? reviews; // Add reviews list

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profilePhoto,
    this.createdAt,
    this.isFollowing = false,
    this.followersCount,
    this.followingCount,
    this.reviewCount = 0, // Default to 0
    this.reviews, // Optional reviews list
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePhoto: json['profile_photo'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      isFollowing: json['is_following'] ?? false,
      followersCount: json['followers_count'],
      followingCount: json['following_count'],
      reviewCount: json['review_count'] ?? 0, // Add this line
      reviews: json['reviews'] != null 
          ? (json['reviews'] as List).map((r) => Review.fromJson(r)).toList()
          : null, // Add this line
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_photo': profilePhoto,
      'created_at': createdAt?.toIso8601String(),
      'is_following': isFollowing,
      'followers_count': followersCount,
      'following_count': followingCount,
      'review_count': reviewCount, // Add this line
      'reviews': reviews?.map((r) => r.toJson()).toList(), // Add this line
    };
  }

  // Helper method to create a copy with updated properties
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? profilePhoto,
    DateTime? createdAt,
    bool? isFollowing,
    int? followersCount,
    int? followingCount,
    int? reviewCount,
    List<Review>? reviews,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      createdAt: createdAt ?? this.createdAt,
      isFollowing: isFollowing ?? this.isFollowing,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      reviewCount: reviewCount ?? this.reviewCount,
      reviews: reviews ?? this.reviews,
    );
  }
}

// You'll also need a Review class if you don't have one already
class Review {
  final int id;
  final String content;
  final double rating;
  final DateTime createdAt;
  final int userId;
  final String? userName;
  final Product? product; // Add this line

  Review({
    required this.id,
    required this.content,
    required this.rating,
    required this.createdAt,
    required this.userId,
    this.userName,
    this.product, // Add this line
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? 0,
      content: json['content'] ?? json['review_text'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      userId: json['user_id'] ?? 0,
      userName: json['user']?['name'],
      product: json['product'] != null 
          ? Product.fromJson(json['product'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
      'user_name': userName,
      'product': product?.toJson(),
    };
  }
}

class Product { // Add this new class
  final int id;
  final String name;
  final String? brand;
  final String? productPhoto;
  final double? averageRating;

  Product({
    required this.id,
    required this.name,
    this.brand,
    this.productPhoto,
    this.averageRating,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      brand: json['brand'],
      productPhoto: json['product_photo'],
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'product_photo': productPhoto,
      'average_rating': averageRating,
    };
  }
}