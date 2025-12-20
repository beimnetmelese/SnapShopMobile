import 'package:flutter_application_1/models/product_model.dart';

class AISearchResponse {
  final String message;
  final String aiAnalysis;
  final List<String> keywordsUsed;
  final int resultsCount;
  final List<Product> results;
  final String? conversationId;
  final DateTime? searchedAt;

  const AISearchResponse({
    required this.message,
    required this.aiAnalysis,
    required this.keywordsUsed,
    required this.resultsCount,
    required this.results,
    this.conversationId,
    this.searchedAt,
  });

  // Factory constructor from JSON
  factory AISearchResponse.fromJson(Map<String, dynamic> json) {
    return AISearchResponse(
      message: json['message'] ?? '',
      aiAnalysis: json['ai_analysis'] ?? '',
      keywordsUsed: List<String>.from(json['keywords_used'] ?? []),
      resultsCount: json['results_count'] ?? 0,
      results:
          (json['results'] as List<dynamic>?)
              ?.map((item) => Product.fromJson(item))
              .toList() ??
          [],
      conversationId: json['conversation_id'],
      searchedAt: json['searched_at'] != null
          ? DateTime.parse(json['searched_at'])
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'ai_analysis': aiAnalysis,
      'keywords_used': keywordsUsed,
      'results_count': resultsCount,
      'results': results.map((product) => product.toJson()).toList(),
      if (conversationId != null) 'conversation_id': conversationId,
      if (searchedAt != null) 'searched_at': searchedAt!.toIso8601String(),
    };
  }
}
