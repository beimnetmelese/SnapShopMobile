import 'package:flutter_application_1/models/user_model.dart';

class Post {
  final int id;
  final User user;
  final String image;
  final String description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  bool isLiked;
  int likesCount;
  int commentsCount;
  final List<Comment> comments;

  Post({
    required this.id,
    required this.user,
    required this.image,
    required this.description,
    required this.createdAt,
    this.updatedAt,
    this.isLiked = false,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.comments = const [],
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    // Debug print
    print('Parsing Post from JSON: $json');

    return Post(
      id: json['id'] as int? ?? 0,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : User(id: 0, username: 'Unknown', email: ''),
      image: json['image'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isLiked: json['is_liked'] as bool? ?? false,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      comments: json['comments'] != null && json['comments'] is List
          ? (json['comments'] as List)
                .where((item) => item != null)
                .map(
                  (comment) =>
                      Comment.fromJson(comment as Map<String, dynamic>),
                )
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'image': image,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_liked': isLiked,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'comments': comments.map((comment) => comment.toJson()).toList(),
    };
  }
}

class Comment {
  final int id;
  final User user;
  final String comment;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.user,
    required this.comment,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int? ?? 0,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : User(id: 0, username: 'Unknown', email: ''),
      comment: json['comment'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'text': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
