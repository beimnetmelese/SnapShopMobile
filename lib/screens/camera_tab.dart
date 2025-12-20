import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_application_1/models/ai_analysis_model.dart';
import 'package:flutter_application_1/models/product_model.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

class CameraTab extends StatefulWidget {
  const CameraTab({super.key});

  @override
  State<CameraTab> createState() => _CameraTabState();
}

class _CameraTabState extends State<CameraTab> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isLoading = true;
  bool _isFlashOn = false;
  CameraLensDirection _direction = CameraLensDirection.back;
  XFile? _capturedImage;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    } else if (state == AppLifecycleState.paused) {
      _controller?.dispose();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      _controller = CameraController(
        _cameras!.firstWhere(
          (camera) => camera.lensDirection == _direction,
          orElse: () => _cameras!.first,
        ),
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Camera error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final XFile picture = await _controller!.takePicture();
      setState(() {
        _capturedImage = picture;
        _showPreview = true;
      });
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _capturedImage = image;
        _showPreview = true;
      });
    }
  }

  void _retakePicture() {
    setState(() {
      _capturedImage = null;
      _showPreview = false;
    });
  }

  void _toggleFlash() {
    setState(() => _isFlashOn = !_isFlashOn);
    _controller?.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;

    setState(() {
      _direction = _direction == CameraLensDirection.back
          ? CameraLensDirection.front
          : CameraLensDirection.back;

      final newCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == _direction,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _controller!.initialize().then((_) {
        if (mounted) setState(() {});
      });
    });
  }

  void _goToAnalysis() async {
    if (_capturedImage == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AnalyzingOverlay(),
    );

    try {
      // Call backend
      final aiResponse = await ApiService.analyzeImage(
        File(_capturedImage!.path),
      );

      if (mounted) {
        Navigator.pop(context); // remove overlay

        // Navigate to results screen and pass AI response
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnalysisResultsScreen(
              imagePath: _capturedImage!.path,
              aiResponse: aiResponse,
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // remove overlay
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Analysis failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _showPreview && _capturedImage != null
          ? _buildPreviewScreen()
          : _buildCameraScreen(),
    );
  }

  Widget _buildCameraScreen() {
    return Stack(
      children: [
        if (_controller != null && _controller!.value.isInitialized)
          CameraPreview(_controller!),

        // Gradient Overlays
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
              ),
            ),
          ),
        ),

        // Top Controls
        Positioned(
          top: 60,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Snap & Shop',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: _pickFromGallery,
                icon: const Icon(
                  Icons.photo_library,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
        ),

        // Center Guide
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Icon(
                Icons.photo_camera,
                color: Colors.white.withOpacity(0.5),
                size: 50,
              ),
            ),
          ),
        ),

        // Bottom Controls
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // Zoom Controls

              // Main Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Flash
                  IconButton(
                    onPressed: _toggleFlash,
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),

                  // Capture Button
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Switch Camera
                  IconButton(
                    onPressed: _switchCamera,
                    icon: const Icon(
                      Icons.flip_camera_ios,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Loading Indicator
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildPreviewScreen() {
    return Stack(
      children: [
        // Image Preview
        Positioned.fill(
          child: Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
        ),

        // Top Bar
        Positioned(
          top: 60,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _retakePicture,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ),

        // Bottom Actions
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Analyze Button
              ElevatedButton.icon(
                onPressed: _goToAnalysis,
                icon: const Icon(Icons.search, size: 20),
                label: const Text('Analyze'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),

        // AI Analysis Indicator
        Positioned(
          top: 120,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'AI Ready for Analysis',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tap "Analyze" to find similar products',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AnalyzingOverlay extends StatelessWidget {
  const AnalyzingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Lottie
            SizedBox(
              width: 180,
              height: 180,
              child: Lottie.asset(
                'lib/assets/animations/ai_scanning.json',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'AI is Analyzing...',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Scanning product details and searching matches',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey.shade800,
                valueColor: const AlwaysStoppedAnimation(Colors.deepPurple),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'This may take a few seconds',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalysisResultsScreen extends StatelessWidget {
  final String imagePath;
  final AIAnalysisResponse aiResponse; // Now receiving the real response

  const AnalysisResultsScreen({
    super.key,
    required this.imagePath,
    required this.aiResponse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Analysis Results'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Original Captured Image
            Container(
              height: 240,
              width: double.infinity,
              child: Image.file(File(imagePath), fit: BoxFit.cover),
            ),

            const SizedBox(height: 20),

            // AI Analysis Summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Colors.deepPurple,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'AI Analysis',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      aiResponse.aiExplanation.isNotEmpty
                          ? aiResponse.aiExplanation
                          : 'No detailed analysis available.',
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                    ),
                    const SizedBox(height: 20),
                    if (aiResponse.suggestedTags.isNotEmpty) ...[
                      Text(
                        'Suggested Tags',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: aiResponse.suggestedTags.map((tag) {
                          return Chip(
                            label: Text('#$tag'),
                            backgroundColor: Colors.deepPurple.withOpacity(
                              0.15,
                            ),
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Similar Products Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Similar Products Found (${aiResponse.results.length})',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Products Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              itemCount: aiResponse.results.length,
              itemBuilder: (context, index) {
                final product = aiResponse.results[index];
                return _buildProductCard(context, product);
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        // Navigate to product detail if needed
        // Navigator.pushNamed(context, '/product-detail', arguments: product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image + Wishlist Button
            Expanded(
              flex: 4, // Increased flex to give more space to image
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: product.imageUrl != null
                        ? Image.network(
                            product.imageUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 60),
                          ),
                  ),
                  // Wishlist Heart Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        icon: const Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          try {
                            await ApiService.addToWishlist(product.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added to wishlist!'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add to wishlist'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product Details - Fixed layout to prevent overflow
            Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                12,
                12,
                8,
              ), // Reduced bottom padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    product.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Price
                  Text(
                    '${product.currency} ${product.price}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Phone Row
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.seller.phone ?? 'No phone',
                          style: TextStyle(
                            fontSize: 12,
                            color: product.seller.phone != null
                                ? Colors.green[700]
                                : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Location + Condition Row
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.seller.location ?? product.seller.platform,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: product.condition == 'New'
                              ? Colors.green.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.condition,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: product.condition == 'New'
                                ? Colors.green[800]
                                : Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
