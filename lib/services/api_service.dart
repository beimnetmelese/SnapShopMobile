import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/models/ai_analysis_model.dart';
import 'package:flutter_application_1/models/ai_search_response.dart';
import 'package:flutter_application_1/models/wishlist_model.dart' hide Product;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;

// Import your models
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/post_model.dart';

class ApiService {
  static const String baseUrl = 'https://2c7ea3bef406.ngrok-free.app';
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static String? _accessToken;
  static String? _refreshToken;

  // Initialize tokens from secure storage
  static Future<void> initialize() async {
    _accessToken = await _secureStorage.read(key: 'access_token');
    _refreshToken = await _secureStorage.read(key: 'refresh_token');
    if (kDebugMode) {
      print(
        'ApiService initialized - Token: ${_accessToken != null ? "Loaded" : "Not found"}',
      );
    }
  }

  static String? get accessToken => _accessToken;
  static String? get refreshToken => _refreshToken;

  // Store tokens securely
  static Future<void> _storeTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    await _secureStorage.write(key: 'access_token', value: access);
    await _secureStorage.write(key: 'refresh_token', value: refresh);
    if (kDebugMode) {
      print('Tokens stored securely');
    }
  }

  // Clear tokens (logout)
  static Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    if (kDebugMode) {
      print('Tokens cleared');
    }
  }

  // Get headers with automatic token inclusion
  static Future<Map<String, String>> _getHeaders({
    bool isMultipart = false,
  }) async {
    final headers = isMultipart
        ? {'Authorization': 'Bearer $_accessToken'}
        : {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_accessToken',
          };

    return headers;
  }

  // Handle API response
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Session expired. Please login again.');
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(
          error['detail'] ??
              error['error'] ??
              error['message'] ??
              'API Error: ${response.statusCode}',
        );
      } catch (e) {
        throw Exception('API Error: ${response.statusCode}');
      }
    }
  }

  // Refresh token if expired
  static Future<void> _refreshTokenIfNeeded() async {
    if (_refreshToken == null) {
      throw Exception('No refresh token found. Please login again.');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storeTokens(data['access'], _refreshToken!);
        if (kDebugMode) {
          print('Token refreshed successfully');
        }
      } else {
        await clearTokens();
        throw Exception('Session expired. Please login again.');
      }
    } catch (e) {
      await clearTokens();
      throw Exception('Session expired. Please login again.');
    }
  }

  // Make API request with automatic token handling
  static Future<http.Response> _makeRequest(
    Future<http.Response> Function() request, {
    bool requireAuth = true,
  }) async {
    if (requireAuth && _accessToken == null) {
      throw Exception('No authentication token found. Please login.');
    }

    try {
      var response = await request();

      // If token expired, refresh and retry
      if (response.statusCode == 401 && requireAuth) {
        await _refreshTokenIfNeeded();
        if (kDebugMode) {
          print('Retrying request after token refresh...');
        }
        response = await request(); // Retry with new token
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Make multipart request for file uploads
  static Future<http.Response> _makeMultipartRequest(
    http.MultipartRequest request,
  ) async {
    // Add token to headers
    final headers = await _getHeaders(isMultipart: true);
    request.headers.addAll(headers);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    // Handle token refresh for multipart requests
    if (response.statusCode == 401) {
      await _refreshTokenIfNeeded();
      // Retry with new token
      final newHeaders = await _getHeaders(isMultipart: true);
      request.headers.clear();
      request.headers.addAll(newHeaders);

      final retryStreamedResponse = await request.send();
      return await http.Response.fromStream(retryStreamedResponse);
    }

    return response;
  }

  // ============ AUTHENTICATION ENDPOINTS ============

  // Login with username (Djoser)
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/jwt/create/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _storeTokens(data['auth_token'] ?? data['access'], '');

      // Fetch user data
      final userResponse = await _makeRequest(
        () async => http.get(
          Uri.parse('$baseUrl/auth/users/me/'),
          headers: await _getHeaders(),
        ),
      );

      final userData = jsonDecode(userResponse.body);

      return {'success': true, 'user': userData, 'access': _accessToken};
    } else {
      final error = jsonDecode(response.body);
      return {
        'success': false,
        'error': error['non_field_errors']?[0] ?? 'Invalid credentials',
      };
    }
  }

  // Register user (Djoser)
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/users/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        "re_password": password,
        'first_name': firstName,
        'last_name': lastName,
      }),
    );

    if (response.statusCode == 201) {
      return await login(username: username, password: password);
    } else {
      final error = jsonDecode(response.body);
      String errorMessage = 'Registration failed';

      if (error.containsKey('username')) {
        errorMessage = 'Username: ${error['username'][0]}';
      } else if (error.containsKey('email')) {
        errorMessage = 'Email: ${error['email'][0]}';
      } else if (error.containsKey('password')) {
        errorMessage = 'Password: ${error['password'][0]}';
      }

      return {'success': false, 'error': errorMessage};
    }
  }

  // Change password (Djoser)
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _makeRequest(
      () async => http.post(
        Uri.parse('$baseUrl/auth/users/set_password/'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      ),
    );

    if (response.statusCode == 204) {
      return {'success': true};
    } else {
      final error = jsonDecode(response.body);
      return {'success': false, 'error': error.toString()};
    }
  }

  // Logout
  static Future<void> logout() async {
    await clearTokens();
  }

  // Get user profile
  static Future<User> getUserProfile() async {
    final response = await _makeRequest(
      () async => http.get(
        Uri.parse('$baseUrl/auth/users/me/'),
        headers: await _getHeaders(),
      ),
    );

    final data = _handleResponse(response);
    return User.fromJson(data);
  }

  // Update user profile
  static Future<User> updateProfile({
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? bio,
    String? phone,
    String? location,
    File? profileImage,
  }) async {
    if (profileImage != null) {
      // Multipart request for image upload
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$baseUrl/auth/users/me/'),
      );

      // Add fields
      if (username != null) request.fields['username'] = username;
      if (email != null) request.fields['email'] = email;
      if (firstName != null) request.fields['first_name'] = firstName;
      if (lastName != null) request.fields['last_name'] = lastName;
      if (bio != null) request.fields['bio'] = bio;
      if (phone != null) request.fields['phone'] = phone;
      if (location != null) request.fields['location'] = location;

      // Add image
      final imageFile = await http.MultipartFile.fromPath(
        'profile_image',
        profileImage.path,
        filename: path.basename(profileImage.path),
      );
      request.files.add(imageFile);

      final response = await _makeMultipartRequest(request);
      final data = _handleResponse(response);
      return User.fromJson(data);
    } else {
      // Regular JSON request
      final Map<String, dynamic> body = {};
      if (username != null) body['username'] = username;
      if (email != null) body['email'] = email;
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (bio != null) body['bio'] = bio;
      if (phone != null) body['phone'] = phone;
      if (location != null) body['location'] = location;

      final response = await _makeRequest(
        () async => http.patch(
          Uri.parse('$baseUrl/auth/users/me/'),
          headers: await _getHeaders(),
          body: jsonEncode(body),
        ),
      );

      final data = _handleResponse(response);
      return User.fromJson(data);
    }
  }

  // Delete account
  static Future<void> deleteAccount() async {
    final response = await _makeRequest(
      () async => http.delete(
        Uri.parse('$baseUrl/auth/users/me/'),
        headers: await _getHeaders(),
      ),
    );

    _handleResponse(response);
    await clearTokens();
  }

  // ============ AI SERVICE ENDPOINTS ============

  // Analyze image and get product matches
  static Future<AIAnalysisResponse> analyzeImage(File image) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/ai/analyze/'),
    );

    // Add image file
    final imageFile = await http.MultipartFile.fromPath(
      'uploaded_image',
      image.path,
      filename: path.basename(image.path),
    );
    request.files.add(imageFile);

    final response = await _makeMultipartRequest(request);
    final data = _handleResponse(response);
    return AIAnalysisResponse.fromJson(data);
  }

  // Search by image (AI-powered search)
  static Future<List<Product>> searchByImage(File image) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/ai/search/'),
    );

    // Add image file
    final imageFile = await http.MultipartFile.fromPath(
      'image',
      image.path,
      filename: path.basename(image.path),
    );
    request.files.add(imageFile);

    final response = await _makeMultipartRequest(request);
    final data = _handleResponse(response);

    final List<dynamic> results = data['results'] ?? [];
    return results.map((json) => Product.fromJson(json)).toList();
  }

  // Search by text query
  static Future<AISearchResponse> searchByText(String query) async {
    final response = await _makeRequest(
      () async => http.post(
        Uri.parse('$baseUrl/ai/search/'),
        headers: await _getHeaders(),
        body: jsonEncode({'query': query}),
      ),
    );

    final data = _handleResponse(response);
    return AISearchResponse.fromJson(data);
  }

  // Combined search (text + image)
  static Future<AISearchResponse> searchCombined({
    String? query,
    File? image,
  }) async {
    if ((query == null || query.isEmpty) && image == null) {
      throw Exception('Either query or image must be provided');
    }

    final uri = Uri.parse('$baseUrl/ai/search/');
    final request = http.MultipartRequest('POST', uri);

    // Add auth headers only (do NOT set Content-Type manually)
    final headers = await _getHeaders();
    request.headers.addAll(headers);

    // Add text query if provided
    if (query != null && query.isNotEmpty) {
      request.fields['query'] = query;
    }

    // Add image if provided
    if (image != null && await image.exists()) {
      final imageFile = await http.MultipartFile.fromPath(
        'image',
        image.path,
        filename: path.basename(image.path),
      );
      request.files.add(imageFile);
    }

    // Send request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    // Check status
    if (response.statusCode >= 400) {
      throw Exception(
        'AI search request failed with status ${response.statusCode}: ${response.body}',
      );
    }

    // Parse JSON response
    final data = _handleResponse(response);
    return AISearchResponse.fromJson(data);
  }

  // AI Chat
  static Future<AISearchResponse> chat({
    required String message,
    File? image,
    String? conversationId,
  }) async {
    if (image != null) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/ai/chat/'),
      );

      request.fields['message'] = message;
      if (conversationId != null) {
        request.fields['conversation_id'] = conversationId;
      }

      final imageFile = await http.MultipartFile.fromPath(
        'image',
        image.path,
        filename: path.basename(image.path),
      );
      request.files.add(imageFile);

      final response = await _makeMultipartRequest(request);
      final data = _handleResponse(response);
      return AISearchResponse.fromJson(data);
    } else {
      final response = await _makeRequest(
        () async => http.post(
          Uri.parse('$baseUrl/ai/search/'),
          headers: await _getHeaders(),
          body: jsonEncode({
            'message': message,
            if (conversationId != null) 'conversation_id': conversationId,
          }),
        ),
      );

      final data = _handleResponse(response);
      return AISearchResponse.fromJson(data);
    }
  }

  // Get trending products
  static Future<List<Product>> getTrendingProducts() async {
    final response = await _makeRequest(
      () async => http.get(
        Uri.parse('$baseUrl/ai/trending/'),
        headers: await _getHeaders(),
      ),
    );

    final data = _handleResponse(response);
    final List<dynamic> results = data['results'] ?? [];
    return results.map((json) => Product.fromJson(json)).toList();
  }

  // Get recommendations
  static Future<List<Product>> getRecommendations() async {
    final response = await _makeRequest(
      () async => http.get(
        Uri.parse('$baseUrl/ai/recommendations/'),
        headers: await _getHeaders(),
      ),
    );

    final data = _handleResponse(response);
    final List<dynamic> results = data['results'] ?? [];
    return results.map((json) => Product.fromJson(json)).toList();
  }

  // Get search history
  // static Future<List<SearchHistory>> getSearchHistory() async {
  //   final response = await _makeRequest(
  //     () async => http.get(
  //       Uri.parse('$baseUrl/ai/search/history/'),
  //       headers: await _getHeaders(),
  //     ),
  //   );

  //   final data = _handleResponse(response);
  //   final List<dynamic> results = data['results'] ?? data;
  //   return results.map((json) => SearchHistory.fromJson(json)).toList();
  // }

  // Clear search history
  static Future<void> clearSearchHistory() async {
    final response = await _makeRequest(
      () async => http.delete(
        Uri.parse('$baseUrl/ai/search/history/'),
        headers: await _getHeaders(),
      ),
    );

    _handleResponse(response);
  }

  // Get analysis history
  static Future<List<AIAnalysis>> getAnalysisHistory() async {
    final response = await _makeRequest(
      () async => http.get(
        Uri.parse('$baseUrl/ai/analyze/history/'),
        headers: await _getHeaders(),
      ),
    );

    final data = _handleResponse(response);
    final List<dynamic> results = data['results'] ?? data;
    return results.map((json) => AIAnalysis.fromJson(json)).toList();
  }

  // Save analysis
  static Future<void> saveAnalysis(int analysisId) async {
    final response = await _makeRequest(
      () async => http.post(
        Uri.parse('$baseUrl/ai/analyze/$analysisId/save/'),
        headers: await _getHeaders(),
      ),
    );

    _handleResponse(response);
  }

  // Get saved analyses
  static Future<List<AIAnalysis>> getSavedAnalyses() async {
    final response = await _makeRequest(
      () async => http.get(
        Uri.parse('$baseUrl/ai/analyze/saved/'),
        headers: await _getHeaders(),
      ),
    );

    final data = _handleResponse(response);
    final List<dynamic> results = data['results'] ?? data;
    return results.map((json) => AIAnalysis.fromJson(json)).toList();
  }

  // ============ POSTS ENDPOINTS ============

  // Get all posts
  static Future<List<Post>> getPosts() async {
    final response = await _makeRequest(
      () async =>
          http.get(Uri.parse('$baseUrl/posts/'), headers: await _getHeaders()),
    );

    // _handleResponse already decodes JSON, so use it directly
    final dynamic data = _handleResponse(response);

    // Debug print to see exactly what you're getting
    print('getPosts raw data: $data (type: ${data.runtimeType})');

    List<dynamic> postsJson;

    // Handle both possible response formats
    if (data is List) {
      // Direct list: [ {post1}, {post2}, ... ]
      postsJson = data;
    } else if (data is Map<String, dynamic>) {
      // Paginated/wrapped response: { "results": [ ... ], "count": 10, ... }
      if (data.containsKey('results')) {
        postsJson = data['results'] as List<dynamic>;
      } else if (data.containsKey('posts')) {
        postsJson = data['posts'] as List<dynamic>;
      } else if (data.containsKey('data')) {
        postsJson = data['data'] as List<dynamic>;
      } else {
        throw Exception(
          'Unexpected response format: no list found in keys ${data.keys}',
        );
      }
    } else {
      throw Exception('Unexpected response type: ${data.runtimeType}');
    }

    // Safely parse each item
    return postsJson
        .map((item) => Post.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // Get my posts
  static Future<List<Post>> getMyPosts() async {
    final response = await _makeRequest(
      () async => http.get(
        Uri.parse('$baseUrl/posts/me/'),
        headers: await _getHeaders(),
      ),
    );

    final data = _handleResponse(response);
    print(data);

    List<dynamic> results;

    if (data is String) {
      results = json.decode(data) as List<dynamic>;
    } else if (data is List) {
      results = data;
    } else {
      throw Exception('Unexpected response format');
    }

    return results.map((json) => Post.fromJson(json)).toList();
  }

  // Get post details
  static Future<Post> getPostDetails(int postId) async {
    final response = await _makeRequest(
      () async => http.get(
        Uri.parse('$baseUrl/posts/$postId/'),
        headers: await _getHeaders(),
      ),
    );

    final data = _handleResponse(response);
    return Post.fromJson(data);
  }

  // Create post
  static Future<Post> createPost({
    required File image,
    required String description,
    List<String> hashtags = const [],
    String? location,
    List<int>? taggedUserIds,
  }) async {
    final uri = Uri.parse('$baseUrl/posts/');
    final request = http.MultipartRequest('POST', uri);

    // ✅ Use your existing getHeaders() function
    request.headers.addAll(await _getHeaders());

    // ✅ TEXT FIELDS
    request.fields['description'] = description;

    if (hashtags.isNotEmpty) {
      request.fields['hashtags'] = jsonEncode(hashtags);
    }

    if (location != null) {
      request.fields['location'] = location;
    }

    if (taggedUserIds != null && taggedUserIds.isNotEmpty) {
      request.fields['tagged_users'] = jsonEncode(taggedUserIds);
    }

    // ✅ IMAGE
    final imageFile = await http.MultipartFile.fromPath(
      'image', // Make sure this matches backend field name
      image.path,
      filename: path.basename(image.path),
      contentType: http.MediaType(
        'image',
        'jpeg',
      ), // Important for proper upload
    );

    request.files.add(imageFile);

    // 🚀 SEND
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final data = _handleResponse(response);
    return Post.fromJson(data);
  }

  // Update post
  static Future<Post> updatePost({
    required int postId,
    String? description,
  }) async {
    final Map<String, dynamic> body = {};
    if (description != null) body['description'] = description;

    final response = await _makeRequest(
      () async => http.patch(
        Uri.parse('$baseUrl/posts/$postId/'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      ),
    );

    final data = _handleResponse(response);
    return Post.fromJson(data);
  }

  // Delete post
  static Future<void> deletePost(int postId) async {
    final response = await _makeRequest(
      () async => http.delete(
        Uri.parse('$baseUrl/posts/$postId/'),
        headers: await _getHeaders(),
      ),
    );

    _handleResponse(response);
  }

  // Like/unlike post
  static Future<bool> toggleLike(int postId) async {
    final response = await _makeRequest(
      () async => http.post(
        Uri.parse('$baseUrl/posts/$postId/like/'),
        headers: await _getHeaders(),
      ),
    );

    final data = _handleResponse(response);
    return data['liked'] ?? false;
  }

  // Add comment
  static Future<Comment> addComment({
    required int postId,
    required String comment,
  }) async {
    final response = await _makeRequest(
      () async => http.post(
        Uri.parse('$baseUrl/posts/$postId/comment/'),
        headers: await _getHeaders(),
        body: jsonEncode({'comment': comment}),
      ),
    );

    final data = _handleResponse(response);
    return Comment.fromJson(data);
  }

  // ============ PRODUCTS ENDPOINTS ============

  // Get all products
  static Future<List<Product>> getProducts({
    int page = 1,
    int pageSize = 10,
    String? category,
    String? search,
  }) async {
    final params = {
      'page': page.toString(),
      'page_size': pageSize.toString(),
      if (category != null) 'category': category,
      if (search != null) 'search': search,
    };

    final uri = Uri.parse(
      '$baseUrl/products/',
    ).replace(queryParameters: params);

    final response = await _makeRequest(
      () async => http.get(uri, headers: await _getHeaders()),
    );

    final data = _handleResponse(response);
    final List<dynamic> results = data['results'] ?? data;
    return results.map((json) => Product.fromJson(json)).toList();
  }

  // Get product details
  static Future<Product> getProductDetails(int productId) async {
    final response = await _makeRequest(
      () async => http.get(
        Uri.parse('$baseUrl/products/$productId/'),
        headers: await _getHeaders(),
      ),
    );

    final data = _handleResponse(response);
    return Product.fromJson(data);
  }

  // ============ WISHLIST ENDPOINTS ============

  // Get wishlist
  static Future<List<WishlistItem>> getWishlist() async {
    final response = await _makeRequest(
      () async => http.get(
        Uri.parse('$baseUrl/wishlist/'),
        headers: await _getHeaders(),
      ),
    );

    final data = _handleResponse(response);
    print(data);

    // Decode JSON if it's a string
    List<dynamic> results;
    if (data is String) {
      results = json.decode(data) as List<dynamic>;
    } else if (data is List) {
      results = data;
    } else {
      throw Exception('Unexpected response format');
    }

    print(results);
    return results.map((json) => WishlistItem.fromJson(json)).toList();
  }

  // Add to wishlist
  static Future<void> addToWishlist(int productId) async {
    final response = await _makeRequest(
      () async => http.post(
        Uri.parse('$baseUrl/wishlist/'),
        headers: await _getHeaders(),
        body: jsonEncode({'product_id': productId}),
      ),
    );

    _handleResponse(response);
  }

  // Remove from wishlist
  static Future<void> removeFromWishlist(int productId) async {
    final response = await _makeRequest(
      () async => http.delete(
        Uri.parse('$baseUrl/wishlist/'),
        headers: await _getHeaders(),
        body: jsonEncode({'product_id': productId}),
      ),
    );

    _handleResponse(response);
  }

  // ============ CATEGORIES ENDPOINTS ============

  // ============ SEARCH ENDPOINTS ============

  // Search products
  static Future<List<Product>> searchProducts({
    required String query,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? condition,
    int page = 1,
    int pageSize = 10,
  }) async {
    final params = {
      'page': page.toString(),
      'page_size': pageSize.toString(),
      'search': query,
      if (category != null) 'category': category,
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
      if (condition != null) 'condition': condition,
    };

    final uri = Uri.parse(
      '$baseUrl/products/',
    ).replace(queryParameters: params);

    final response = await _makeRequest(
      () async => http.get(uri, headers: await _getHeaders()),
    );

    final data = _handleResponse(response);
    final List<dynamic> results = data['results'] ?? data;
    return results.map((json) => Product.fromJson(json)).toList();
  }

  // ============ UTILITY METHODS ============

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    await initialize();
    return _accessToken != null && _accessToken!.isNotEmpty;
  }

  // Validate image before upload
  static bool validateImage(File image) {
    try {
      // Check file size (max 10MB)
      final sizeInBytes = image.lengthSync();
      const maxSize = 10 * 1024 * 1024; // 10MB

      if (sizeInBytes > maxSize) {
        throw Exception('Image size should be less than 10MB');
      }

      // Check file extension
      final extension = path.extension(image.path).toLowerCase();
      final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

      if (!allowedExtensions.contains(extension)) {
        throw Exception('Only JPG, PNG, and WebP images are allowed');
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Compress image (placeholder - implement actual compression)
  static Future<File> compressImage(File image) async {
    // TODO: Implement image compression
    // For now, return original image
    return image;
  }

  // Get current user ID from token
  static int? getCurrentUserId() {
    if (_accessToken == null) return null;

    try {
      // Decode JWT token to get user ID
      final parts = _accessToken!.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payloadMap = jsonDecode(decoded);

      return payloadMap['user_id'];
    } catch (e) {
      if (kDebugMode) {
        print('Error decoding token: $e');
      }
      return null;
    }
  }

  // Clear all data (for logout)
  static Future<void> clearAllData() async {
    await clearTokens();
    // Clear any other cached data if needed
  }

  // Network error handler
  static String getErrorMessage(dynamic error) {
    if (error is String) return error;
    if (error is Exception) return error.toString();
    return 'An unexpected error occurred';
  }

  // Create custom exception
  static Exception createApiException(dynamic error) {
    if (error is Exception) return error;
    return Exception(error.toString());
  }
}

// Helper class for API response handling
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResponse({required this.success, this.data, this.error, this.statusCode});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJson,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? fromJson(json['data']) : null,
      error: json['error'],
      statusCode: json['status_code'],
    );
  }
}
