class Product {
  final int id;
  final String title;
  final String? description;
  final String price;
  final String currency;
  final String condition;
  final String? imageUrl;
  final String? productUrl;
  final Category category;
  final Seller seller;
  final DateTime dateScraped;

  Product({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    this.currency = 'ETB',
    this.condition = 'Used',
    this.imageUrl,
    this.productUrl,
    required this.category,
    required this.seller,
    required this.dateScraped,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      price: json['price'] ?? 0.0,
      currency: json['currency'] ?? 'ETB',
      condition: json['condition'] ?? 'Used',
      imageUrl: json['image_url'],
      productUrl: json['product_url'],
      category: Category.fromJson(json['category']),
      seller: Seller.fromJson(json['seller']),
      dateScraped: DateTime.parse(json['date_scraped']),
    );
  }

  toJson() {}
}

class Category {
  final int id;
  final String name;
  final String slug;

  Category({required this.id, required this.name, required this.slug});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(id: json['id'], name: json['name'], slug: json['slug']);
  }
}

class Seller {
  final int id;
  final String? name;
  final String? phone;
  final String? location;
  final String platform;

  Seller({
    required this.id,
    this.name,
    this.phone,
    this.location,
    this.platform = 'Jiji',
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      location: json['location'],
      platform: json['platform'] ?? 'Jiji',
    );
  }
}
