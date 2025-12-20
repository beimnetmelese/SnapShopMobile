import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/product_model.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _recentSearches = [
    'iPhone 15',
    'Gaming Laptop',
    'Sneakers',
    'Furniture',
    'Camera',
  ];
  List<String> _trendingSearches = [
    '#blackfriday',
    '#gamingpc',
    '#phones',
    '#fashion',
    '#homeappliances',
  ];
  List<Product> _searchResults = [];
  bool _isSearching = false;
  bool _showImageSearch = false;
  File? _searchImage;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      if (!_recentSearches.contains(query)) {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) {
          _recentSearches.removeLast();
        }
      }
    });

    try {
      final results = await ApiService.searchByText(query);
      setState(() {
        _searchResults = results as List<Product>;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _searchByImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _searchImage = File(image.path);
        _showImageSearch = true;
      });

      // Perform AI image search
      _performImageSearch();
    }
  }

  Future<void> _performImageSearch() async {
    setState(() => _isSearching = true);

    try {
      final results = await ApiService.searchByImage(_searchImage!);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _showImageSearch = false;
      _searchImage = null;
    });
  }

  void _removeRecentSearch(int index) {
    setState(() => _recentSearches.removeAt(index));
  }

  void _clearAllRecentSearches() {
    setState(() => _recentSearches.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            title: _showImageSearch
                ? Text(
                    'Image Search',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : _buildSearchField(),
            actions: _showImageSearch
                ? [
                    IconButton(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close),
                    ),
                  ]
                : null,
          ),

          if (_showImageSearch && _searchImage != null)
            SliverToBoxAdapter(child: _buildImageSearchPreview()),

          if (_isSearching)
            SliverToBoxAdapter(child: _buildLoadingIndicator())
          else if (_searchResults.isNotEmpty)
            _buildSearchResults()
          else
            _buildSearchSuggestions(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search products...',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: _clearSearch,
                        icon: Icon(
                          Icons.close,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                      )
                    : IconButton(
                        onPressed: _searchByImage,
                        icon: Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
              ),
              onSubmitted: _performSearch,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSearchPreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Searching by image',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: FileImage(_searchImage!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _performImageSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Search Again'),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _clearSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.grey.shade800,
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurple),
          const SizedBox(height: 20),
          Text(
            'Searching...',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  SliverList _buildSearchResults() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final product = _searchResults[index];
        return _buildProductItem(product, index);
      }, childCount: _searchResults.length),
    );
  }

  Widget _buildProductItem(Product product, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              image: DecorationImage(
                image: NetworkImage(product.imageUrl ?? ''),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Product Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price} ${product.currency}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product.seller.location ?? 'Unknown',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.favorite_border,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('View'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SliverList _buildSearchSuggestions() {
    return SliverList(
      delegate: SliverChildListDelegate([
        // Recent Searches
        if (_recentSearches.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Searches',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: _clearAllRecentSearches,
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _recentSearches.asMap().entries.map((entry) {
                    return Chip(
                      label: Text(entry.value),
                      onDeleted: () => _removeRecentSearch(entry.key),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      backgroundColor: Colors.grey.shade100,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

        // Trending Searches
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trending Now',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3,
                ),
                itemCount: _trendingSearches.length,
                itemBuilder: (context, index) {
                  return _buildTrendingItem(_trendingSearches[index]);
                },
              ),
            ],
          ),
        ),

        // Categories
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Browse Categories',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return _buildCategoryItem(categories[index]);
                  },
                ),
              ),
            ],
          ),
        ),

        // AI Search Card
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.deepPurple.shade600, Colors.purple.shade600],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI-Powered Search',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Search with images or describe what you need',
                        style: TextStyle(color: Colors.white.withOpacity(0.9)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/ai-chat');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple,
                        ),
                        child: const Text('Try AI Assistant'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Icon(Icons.auto_awesome, color: Colors.white, size: 60),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildTrendingItem(String hashtag) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
      ),
      child: Center(
        child: Text(
          hashtag,
          style: TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getCategoryIcon(category),
              color: Colors.deepPurple,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.phone_iphone;
      case 'fashion':
        return Icons.shopping_bag;
      case 'home':
        return Icons.home;
      case 'vehicles':
        return Icons.directions_car;
      case 'sports':
        return Icons.sports_basketball;
      default:
        return Icons.category;
    }
  }
}

final List<String> categories = [
  'Electronics',
  'Fashion',
  'Home',
  'Vehicles',
  'Sports',
  'Beauty',
  'Books',
  'Toys',
];
