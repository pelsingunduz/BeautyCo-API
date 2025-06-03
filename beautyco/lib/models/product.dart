class Product {
  final int id;
  final String name;
  final String? brand;
  final int? categoryId;
  final String? description;
  final double? averageRating; // Bu property eklendi
  final String? productPhoto;
  final String? categoryName;

  Product({
    required this.id,
    required this.name,
    this.brand,
    this.categoryId,
    this.description,
    this.averageRating, // Constructor'a eklendi
    this.productPhoto,
    this.categoryName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      brand: json['brand'],
      categoryId: json['categoryId'],
      description: json['description'],
      averageRating: json['averageRating']?.toDouble(), // JSON'dan parse edildi
      productPhoto: json['productPhoto'],
      categoryName: json['categoryName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'categoryId': categoryId,
      'description': description,
      'averageRating': averageRating, // toJson'a eklendi
      'productPhoto': productPhoto,
      'categoryName': categoryName,
    };
  }

  @override
  String toString() {
    return 'Product{id: $id, name: $name, brand: $brand, categoryId: $categoryId, description: $description, averageRating: $averageRating, productPhoto: $productPhoto, categoryName: $categoryName}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Convenience getter'lar
  String get displayName => name;
  String get displayBrand => brand ?? 'Bilinmeyen Marka';
  String get displayDescription => description ?? 'Açıklama bulunmuyor';
  double get displayRating => averageRating ?? 0.0;
  bool get hasRating => averageRating != null && averageRating! > 0;
  
  // Rating için yıldız sayısını hesaplayan method
  int get fullStars => averageRating?.floor() ?? 0;
  bool get hasHalfStar => averageRating != null && (averageRating! - fullStars) >= 0.5;
  int get emptyStars => 5 - fullStars - (hasHalfStar ? 1 : 0);
}