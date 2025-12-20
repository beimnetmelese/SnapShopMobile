import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/post_model.dart';
import 'package:flutter_application_1/screens/post_detail_screen.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shimmer/shimmer.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Post> _myPosts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMorePosts = true;
  final int _pageSize = 10;
  String _selectedFilter = 'all'; // 'all', 'popular', 'recent'
  String _selectedSort = 'newest';

  List<Post>? get posts => null; // 'newest', 'oldest', 'most_liked'

  @override
  void initState() {
    super.initState();
    _loadMyPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMyPosts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _hasMorePosts = true;
        _myPosts.clear();
      });
    }

    if (!refresh) {
      setState(() => _isLoading = true);
    }

    try {
      final List<Post> posts = await ApiService.getMyPosts();
      setState(() {
        if (refresh) {
          _myPosts = posts;
        } else {
          _myPosts.addAll(posts);
        }
        _hasMorePosts = posts.length == _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      _showErrorSnackbar('Failed to load posts');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {}
  }

  Future<void> _refreshPosts() async {
    await _loadMyPosts(refresh: true);
  }

  Future<void> _deletePost(int postId, int index) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading overlay
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                await ApiService.deletePost(postId);

                if (mounted) {
                  Navigator.pop(context); // Remove loading overlay

                  // Remove from list with animation
                  setState(() {
                    _myPosts.removeAt(index);
                  });

                  _showSuccessSnackbar('Post deleted successfully');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Remove loading overlay
                  _showErrorSnackbar('Failed to delete post');
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _editPost(Post post) async {
    // Navigate to edit post screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPostScreen(post: post)),
    );

    if (result == true && mounted) {
      await _refreshPosts();
    }
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        currentFilter: _selectedFilter,
        currentSort: _selectedSort,
        onFilterChanged: (filter) {
          setState(() => _selectedFilter = filter);
          _refreshPosts();
        },
        onSortChanged: (sort) {
          setState(() => _selectedSort = sort);
          _refreshPosts();
        },
      ),
    );
  }

  void _showPostOptions(Post post, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Post'),
              onTap: () {
                Navigator.pop(context);
                _editPost(post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Post'),
              onTap: () {
                Navigator.pop(context);
                _deletePost(post.id, index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.green),
              title: const Text('Share Post'),
              onTap: () {
                Navigator.pop(context);
                _sharePost(post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.purple),
              title: const Text('View Insights'),
              onTap: () {
                Navigator.pop(context);
                _viewInsights(post);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sharePost(Post post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share Post',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _buildShareOption(Icons.copy, 'Copy Link'),
                _buildShareOption(Icons.share, 'Share'),
                _buildShareOption(Icons.message, 'Message'),
                _buildShareOption(Icons.bookmark, 'Save'),
                _buildShareOption(Icons.qr_code, 'QR Code'),
                _buildShareOption(Icons.more_horiz, 'More'),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.deepPurple.withOpacity(0.1),
          ),
          child: Icon(icon, color: Colors.deepPurple, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _viewInsights(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PostInsightsScreen(post: post)),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green.shade600),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('My Posts'),
        centerTitle: false,
        actions: [
          // Filter Button
          IconButton(
            onPressed: _showFilterOptions,
            icon: Badge(
              label: const Text('2'),
              child: const Icon(Icons.filter_list),
            ),
          ),

          // Create Post Button
          IconButton(
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/create-post');
              if (result == true && mounted) {
                await _refreshPosts();
              }
            },
            icon: const Icon(Icons.add),
          ),

          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        color: Colors.deepPurple,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Stats Overview
            if (!_isLoading && _myPosts.isNotEmpty)
              SliverToBoxAdapter(child: _buildStatsOverview()),

            // Posts Grid/List
            if (_isLoading && _myPosts.isEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildPostShimmer(),
                  childCount: 3,
                ),
              )
            else if (_myPosts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Posts Yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Share your first post with the community!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/create-post',
                          );
                          if (result == true && mounted) {
                            await _refreshPosts();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Create Your First Post'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final post = _myPosts[index];
                  return _buildPostGridItem(post, index);
                }, childCount: _myPosts.length),
              ),

            // Loading More Indicator
            if (_isLoadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ),

            // No More Posts
            if (!_hasMorePosts && _myPosts.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No more posts',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/create-post');
          if (result == true && mounted) {
            await _refreshPosts();
          }
        },
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsOverview() {
    final totalLikes = _myPosts.fold(0, (sum, post) => sum + post.likesCount);
    final totalComments = _myPosts.fold(
      0,
      (sum, post) => sum + post.commentsCount,
    );
    final totalPosts = _myPosts.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.photo_library, 'Posts', totalPosts.toString()),
          _buildStatItem(Icons.favorite, 'Likes', totalLikes.toString()),
          _buildStatItem(Icons.comment, 'Comments', totalComments.toString()),
          _buildStatItem(Icons.visibility, 'Views', '1.2K'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.deepPurple.withOpacity(0.1),
          ),
          child: Icon(icon, color: Colors.deepPurple, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildPostGridItem(Post post, int index) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailScreen(postId: post.id),
        ),
      ),
      onLongPress: () => _showPostOptions(post, index),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
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
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Bottom Info
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Likes & Comments
                  Row(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.favorite, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likesCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Icon(Icons.comment, color: Colors.white, size: 12),
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
                    ],
                  ),

                  // Date
                  Text(
                    timeago.format(post.createdAt),
                    style: const TextStyle(color: Colors.white70, fontSize: 9),
                  ),
                ],
              ),
            ),

            // More Options Button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _showPostOptions(post, index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),

            // Draft Badge
          ],
        ),
      ),
    );
  }

  Widget _buildPostShimmer() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 12,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Filter Bottom Sheet
class FilterBottomSheet extends StatefulWidget {
  final String currentFilter;
  final String currentSort;
  final Function(String) onFilterChanged;
  final Function(String) onSortChanged;

  const FilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.currentSort,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String _selectedFilter;
  late String _selectedSort;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.currentFilter;
    _selectedSort = widget.currentSort;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Filter & Sort',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Filter Section
          Text(
            'FILTER BY',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('All', 'all'),
              _buildFilterChip('Popular', 'popular'),
              _buildFilterChip('Recent', 'recent'),
              _buildFilterChip('With Comments', 'with_comments'),
              _buildFilterChip('Liked', 'liked'),
            ],
          ),

          const SizedBox(height: 30),

          // Sort Section
          Text(
            'SORT BY',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSortChip('Newest First', 'newest'),
              _buildSortChip('Oldest First', 'oldest'),
              _buildSortChip('Most Liked', 'most_liked'),
              _buildSortChip('Most Comments', 'most_comments'),
            ],
          ),

          const SizedBox(height: 30),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onFilterChanged(_selectedFilter);
                widget.onSortChanged(_selectedSort);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Apply Filters'),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      selectedColor: Colors.deepPurple,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _selectedSort == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedSort = value);
      },
      selectedColor: Colors.deepPurple,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
        ),
      ),
    );
  }
}

// Edit Post Screen
class EditPostScreen extends StatefulWidget {
  final Post post;

  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late TextEditingController _descriptionController;
  final List<String> _hashtags = [];
  final TextEditingController _hashtagController = TextEditingController();
  bool _isSaving = false;
  bool _showHashtagField = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.post.description,
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      await ApiService.updatePost(
        postId: widget.post.id,
        description: _descriptionController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update post'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _addHashtag() {
    final tag = _hashtagController.text.trim();
    if (tag.isNotEmpty && !tag.startsWith('#')) {
      setState(() {
        _hashtags.add('#$tag');
        _hashtagController.clear();
        _showHashtagField = false;
      });
    }
  }

  void _removeHashtag(int index) {
    setState(() => _hashtags.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Post Image Preview
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(widget.post.image),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Hashtags
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hashtags',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => setState(
                        () => _showHashtagField = !_showHashtagField,
                      ),
                      icon: Icon(
                        _showHashtagField ? Icons.remove : Icons.add,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),

                if (_showHashtagField)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _hashtagController,
                            decoration: InputDecoration(
                              hintText: 'Add a hashtag',
                              prefixText: '#',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onSubmitted: (_) => _addHashtag(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addHashtag,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ),

                // Hashtag chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _hashtags.asMap().entries.map((entry) {
                    return Chip(
                      label: Text(entry.value),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeHashtag(entry.key),
                    );
                  }).toList(),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Post Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildEditStat('Likes', '${widget.post.likesCount}'),
                  _buildEditStat('Comments', '${widget.post.commentsCount}'),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEditStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }
}

// Post Insights Screen
class PostInsightsScreen extends StatelessWidget {
  final Post post;

  const PostInsightsScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Insights')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(post.image),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Post Performance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeago.format(post.createdAt),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Key Metrics
            Text(
              'Key Metrics',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildMetricCard(
                  Icons.favorite,
                  'Likes',
                  '${post.likesCount}',
                  '+12%',
                ),
                _buildMetricCard(
                  Icons.comment,
                  'Comments',
                  '${post.commentsCount}',
                  '+8%',
                ),
                _buildMetricCard(Icons.visibility, 'Views', '1.2K', '+25%'),
              ],
            ),

            const SizedBox(height: 30),

            // Engagement Rate
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Engagement Rate',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '4.8%',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '+1.2% from previous posts',
                    style: TextStyle(color: Colors.green.shade600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Audience Insights
            Text(
              'Audience Insights',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInsightRow('Top Location', 'United States', '32%'),
                  const Divider(),
                  _buildInsightRow('Age Group', '18-24', '45%'),
                  const Divider(),
                  _buildInsightRow('Gender', 'Female', '58%'),
                  const Divider(),
                  _buildInsightRow('Peak Time', '7-9 PM', '+40% engagement'),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    IconData icon,
    String title,
    String value,
    String change,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurple, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value, String percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(percentage, style: TextStyle(color: Colors.deepPurple)),
        ],
      ),
    );
  }
}
