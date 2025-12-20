import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/post_model.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/models/wishlist_model.dart';
import 'package:flutter_application_1/screens/post_detail_screen.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  User? _user;
  List<Post> _userPosts = [];
  List<WishlistItem> _wishlistItems = [];
  int _selectedTab = 0;
  bool _isLoading = true;
  bool _isLoadingPosts = true;
  bool _isLoadingWishlist = true;

  // Stats

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);

      // Load user profile
      final user = await ApiService.getUserProfile();

      // Load posts and wishlist in parallel
      await Future.wait([_loadUserPosts(), _loadWishlist()]);

      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Failed to load profile data');
      }
    }
  }

  Future<void> _loadUserPosts() async {
    try {
      setState(() => _isLoadingPosts = true);

      final posts = await ApiService.getMyPosts();

      setState(() {
        _userPosts = posts;
        _isLoadingPosts = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPosts = false);
        _showErrorSnackbar('Failed to load posts $e');
      }
    }
  }

  Future<void> _loadWishlist() async {
    try {
      setState(() => _isLoadingWishlist = true);

      final wishlist = await ApiService.getWishlist();

      setState(() {
        _wishlistItems = wishlist;
        _isLoadingWishlist = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingWishlist = false);
        _showErrorSnackbar('Failed to load wishlist $e');
      }
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([_loadUserPosts(), _loadWishlist()]);
  }

  Future<void> _removeFromWishlist(WishlistItem item, int index) async {
    try {
      await ApiService.removeFromWishlist(item.product.id);

      setState(() {
        _wishlistItems.removeAt(index);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from wishlist'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Failed to remove from wishlist');
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // 1️⃣ Close dialog FIRST
              Navigator.of(dialogContext).pop();

              // 2️⃣ Clear tokens
              await ApiService.logout();

              if (!mounted) return;

              // 3️⃣ Navigate using ROOT navigator
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamedAndRemoveUntil('/welcome', (route) => false);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: CustomScrollView(
                slivers: [
                  // Profile Header
                  SliverAppBar(
                    expandedHeight: 280,
                    floating: false,
                    pinned: true,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildProfileHeader(),
                    ),
                    actions: [
                      IconButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/settings'),
                        icon: const Icon(Icons.settings_outlined),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),

                  // Stats Section

                  // Tabs
                  SliverToBoxAdapter(child: _buildProfileTabs()),

                  // Content based on selected tab
                  if (_selectedTab == 0) _buildPostsSection(),
                  if (_selectedTab == 1) _buildWishlistSection(),

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.deepPurple.shade700, Colors.purple.shade600],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 50),

          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  image: null,
                ),
                child: const Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // User Info
          Text(
            _user?.username ?? 'User',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            _user?.email ?? 'user@example.com',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      side: const BorderSide(color: Colors.white),
                    ),
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              0,
              Icons.grid_on,
              'Posts',
              _userPosts.length,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              1,
              Icons.favorite_border,
              'Wishlist',
              _wishlistItems.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label, int count) {
    final isSelected = _selectedTab == index;

    return TextButton(
      onPressed: () => setState(() => _selectedTab = index),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isSelected
            ? Colors.deepPurple.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.deepPurple : Colors.grey.shade600,
                size: 24,
              ),
              if (count > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    child: Text(
                      count > 9 ? '9+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.deepPurple : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Posts Section
  SliverList _buildPostsSection() {
    return SliverList(
      delegate: SliverChildListDelegate([
        if (_isLoadingPosts)
          _buildLoadingShimmer()
        else if (_userPosts.isEmpty)
          _buildEmptyState(
            icon: Icons.photo_library_outlined,
            title: 'No Posts Yet',
            message: 'Share your first post with the community!',
            buttonText: 'Create Post',
            onPressed: () => Navigator.pushNamed(context, '/create-post'),
          )
        else
          _buildPostsGrid(),
      ]),
    );
  }

  Widget _buildPostsGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 1,
        ),
        itemCount: _userPosts.length,
        itemBuilder: (context, index) {
          return _buildPostGridItem(_userPosts[index]);
        },
      ),
    );
  }

  Widget _buildPostGridItem(Post post) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailScreen(postId: post.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Post Image
            CachedNetworkImage(
              imageUrl: post.image,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(color: Colors.grey.shade200),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.error),
              ),
            ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                ),
              ),
            ),

            // Stats
            Positioned(
              bottom: 8,
              left: 8,
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likesCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.comment, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentsCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Wishlist Section
  SliverList _buildWishlistSection() {
    return SliverList(
      delegate: SliverChildListDelegate([
        if (_isLoadingWishlist)
          _buildLoadingShimmer()
        else if (_wishlistItems.isEmpty)
          _buildEmptyState(
            icon: Icons.favorite_border,
            title: 'No Saved Items',
            message: 'Save products you love to see them here',
            buttonText: 'Browse Products',
            onPressed: () {
              // Navigate to products/search
              Navigator.pushNamed(context, '/search');
            },
          )
        else
          _buildWishlistItems(),
      ]),
    );
  }

  Widget _buildWishlistItems() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saved Items (${_wishlistItems.length})',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._wishlistItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildWishlistItem(item, index);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildWishlistItem(WishlistItem item, int index) {
    final product = item.product;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        children: [
          // Product Image and Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      // Title and Price
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeFromWishlist(item, index),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Price
                      Text(
                        '${product.price} ${product.currency}',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Category and Condition
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.category.name,
                              style: TextStyle(
                                color: Colors.deepPurple,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.condition,
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Seller Info with Phone
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              product.seller.name ?? 'Unknown Seller',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Phone Number (if available)
                      if (product.seller.phone != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              product.seller.phone!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 4),

                      // Location
                      if (product.seller.location != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                product.seller.location!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // View product details
                    },
                    icon: const Icon(Icons.remove_red_eye, size: 16),
                    label: const Text('View'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Contact seller
                      if (product.seller.phone != null) {
                        // Implement call functionality
                      }
                    },
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text('Contact'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(3, (index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 120,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
