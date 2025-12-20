import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/post_model.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostDetailScreen extends StatefulWidget {
  final int postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Post _post;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = true;
  bool _isLiking = false;
  bool _isCommenting = false;

  @override
  void initState() {
    super.initState();
    _loadPostDetails();
  }

  Future<void> _loadPostDetails() async {
    try {
      final post = await ApiService.getPostDetails(widget.postId);
      setState(() {
        _post = post;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Failed to load post');
    }
  }

  Future<void> _toggleLike() async {
    if (_isLiking) return;

    setState(() => _isLiking = true);
    try {
      await ApiService.toggleLike(widget.postId);
      setState(() {
        _post.isLiked = !_post.isLiked;
        _post.likesCount += _post.isLiked ? 1 : -1;
      });
    } catch (e) {
      _showErrorSnackbar('Failed to update like');
    } finally {
      setState(() => _isLiking = false);
    }
  }

  Future<void> _addComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty || _isCommenting) return;

    setState(() => _isCommenting = true);
    try {
      final newComment = await ApiService.addComment(
        postId: widget.postId,
        comment: comment,
      );

      setState(() {
        _post.comments.add(newComment);
        _commentController.clear();
      });

      // Clear focus
      FocusScope.of(context).unfocus();
    } catch (e) {
      _showErrorSnackbar('Failed to add comment $e');
    } finally {
      setState(() => _isCommenting = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
    );
  }

  void _sharePost() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 400,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.black,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Post Image
                          CachedNetworkImage(
                            imageUrl: _post.image,
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
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),

                          // Back Button
                          Positioned(
                            top: 50,
                            left: 16,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.5),
                              ),
                              child: IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),

                          // More Options

                          // Bottom Info
                          Positioned(
                            bottom: 20,
                            left: 20,
                            right: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Username
                                Text(
                                  _post.user.username,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Description
                                if (_post.description.isNotEmpty)
                                  Text(
                                    _post.description,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      shadows: const [
                                        Shadow(
                                          blurRadius: 10,
                                          color: Colors.black,
                                        ),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                const SizedBox(height: 8),

                                // Date & Stats
                                Row(
                                  children: [
                                    Text(
                                      timeago.format(_post.createdAt),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.favorite,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_post.likesCount}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.comment,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_post.commentsCount}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: _buildCommentsSection(),
            ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      children: [
        // Actions Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              // Like Button
              Expanded(
                child: TextButton.icon(
                  onPressed: _toggleLike,
                  icon: Icon(
                    _post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _post.isLiked ? Colors.red : Colors.grey.shade600,
                  ),
                  label: Text(
                    _post.isLiked ? 'Liked' : 'Like',
                    style: TextStyle(
                      color: _post.isLiked ? Colors.red : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),

              // Comment Button
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    FocusScope.of(context).requestFocus(FocusNode());
                    Future.delayed(const Duration(milliseconds: 100), () {
                      FocusScope.of(context).requestFocus(FocusNode());
                    });
                  },
                  icon: const Icon(Icons.comment, color: Colors.grey),
                  label: const Text(
                    'Comment',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

              // Share Button
              Expanded(
                child: TextButton.icon(
                  onPressed: _sharePost,
                  icon: const Icon(Icons.share, color: Colors.grey),
                  label: const Text(
                    'Share',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Comments Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Comments',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_post.commentsCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Comments List
        Expanded(
          child: _post.comments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 60,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No comments yet',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to comment!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: _post.comments.length,
                  itemBuilder: (context, index) {
                    return _buildCommentItem(_post.comments[index]);
                  },
                ),
        ),

        // Comment Input
        _buildCommentInput(),
      ],
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar

          // Comment Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.user.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(comment.comment),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Row(
                    children: [
                      Text(
                        timeago.format(comment.createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // User Avatar
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey,
            ),
            child: const Icon(Icons.person, color: Colors.white),
          ),

          const SizedBox(width: 12),

          // Text Field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                    ),
                  ),

                  // Send Button
                  IconButton(
                    onPressed: _isCommenting ? null : _addComment,
                    icon: _isCommenting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.send,
                            color: _commentController.text.isEmpty
                                ? Colors.grey.shade400
                                : Colors.deepPurple,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
