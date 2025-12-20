class WishlistItem {
  final int id;
  final int userId;
  final Product product;
  final DateTime addedAt;
  final String? notes;
  final int? priority;
  final String? tags;
  final bool isActive;

  WishlistItem({
    required this.id,
    required this.userId,
    required this.product,
    required this.addedAt,
    this.notes,
    this.priority,
    this.tags,
    this.isActive = true,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user'] ?? json['user_id']),
      product: Product.fromJson(json['product']),
      addedAt: DateTime.parse(json['added_at']),
      notes: json['notes'],
      priority: _parseInt(json['priority']),
      tags: json['tags'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'product': product.toJson(),
      'added_at': addedAt.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (priority != null) 'priority': priority,
      if (tags != null) 'tags': tags,
      'is_active': isActive,
    };
  }

  // Helper to safely parse int from dynamic
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class Product {
  final int id;
  final String title;
  final String? description;
  final double price;
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
      id: WishlistItem._parseInt(json['id']),
      title: json['title'],
      description: json['description'],
      price: _parseDouble(json['price']),
      currency: json['currency'] ?? 'ETB',
      condition: json['condition'] ?? 'Used',
      imageUrl: json['image_url'],
      productUrl: json['product_url'],
      category: Category.fromJson(json['category']),
      seller: Seller.fromJson(json['seller']),
      dateScraped: DateTime.parse(json['date_scraped']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'condition': condition,
      'image_url': imageUrl,
      'product_url': productUrl,
      'category': category.toJson(),
      'seller': seller.toJson(),
      'date_scraped': dateScraped.toIso8601String(),
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class Category {
  final int id;
  final String name;
  final String slug;
  final String? jijiUrl;
  final int? parent;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.jijiUrl,
    this.parent,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: WishlistItem._parseInt(json['id']),
      name: json['name'],
      slug: json['slug'],
      jijiUrl: json['jiji_url'],
      parent: json['parent'] != null
          ? WishlistItem._parseInt(json['parent'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'jiji_url': jijiUrl,
      'parent': parent,
    };
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
      id: WishlistItem._parseInt(json['id']),
      name: json['name'],
      phone: json['phone'],
      location: json['location'],
      platform: json['platform'] ?? 'Jiji',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'location': location,
      'platform': platform,
    };
  }
}
