import 'package:flutter_application_1/models/product_model.dart';

class AIAnalysis {
  final int id;
  final String uploadedImage;
  final List<String> tags;
  final String predictedCategory;
  final double confidence;
  final DateTime createdAt;

  AIAnalysis({
    required this.id,
    required this.uploadedImage,
    required this.tags,
    required this.predictedCategory,
    required this.confidence,
    required this.createdAt,
  });

  factory AIAnalysis.fromJson(Map<String, dynamic> json) {
    return AIAnalysis(
      id: json['id'],
      uploadedImage: json['uploaded_image'],
      tags: List<String>.from(json['tags'] ?? []),
      predictedCategory: json['predicted_category'] ?? '',
      confidence: json['confidence']?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class AIAnalysisResponse {
  final String aiExplanation;
  final List<String> suggestedTags;
  final List<Product> results;

  AIAnalysisResponse({
    required this.aiExplanation,
    required this.suggestedTags,
    required this.results,
  });

  factory AIAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return AIAnalysisResponse(
      aiExplanation: json['ai_explanation'] ?? '',
      suggestedTags: List<String>.from(json['suggested_tags'] ?? []),
      results: (json['results'] as List)
          .map((item) => Product.fromJson(item))
          .toList(),
    );
  }
}
