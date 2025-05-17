// models/product.dart - Düzeltilmiş Product modeli

class Product {
  final int id;
  final String name;
  final String? brand;
  final String? description;
  final String? productPhoto;
  final int? categoryId;

  Product({
    required this.id,
    required this.name,
    this.brand,
    this.description,
    this.productPhoto,
    this.categoryId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Hata ayıklama
    print('Parsing product from JSON: $json');
    
    // id değeri için özel kontrol
    var productId = json['id'];
    if (productId is String) {
      // Bazı API'ler id'yi string olarak döndürebilir
      try {
        productId = int.parse(productId);
      } catch (e) {
        print('Error parsing id as int: $e');
        // Varsayılan bir id kullan
        productId = 0;
      }
    } else if (productId == null) {
      print('Warning: Product ID is null');
      productId = 0;
    }
    
    // Özellikle name alanının varlığını kontrol et
    final name = json['name'];
    if (name == null || (name is String && name.isEmpty)) {
      print('Warning: Product name is null or empty, using default name');
    }
        
    // categoryId değeri için özel kontrol
    var categoryId = json['categoryId'];
    if (categoryId is String) {
      try {
        categoryId = int.parse(categoryId);
      } catch (e) {
        print('Error parsing categoryId as int, setting to null: $e');
        categoryId = null;
      }
    }
    
    return Product(
      id: productId,
      name: name?.toString() ?? 'İsimsiz Ürün',
      brand: json['brand']?.toString(),
      description: json['description']?.toString(),
      productPhoto: json['productPhoto']?.toString(),
      categoryId: categoryId,
    );
  }
  
  // debugging için
  @override
  String toString() {
    return 'Product{id: $id, name: $name, brand: $brand, categoryId: $categoryId}';
  }
}