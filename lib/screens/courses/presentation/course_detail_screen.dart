import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../factories/course_repository_factory.dart';
import '../../../screens/courses/data/models/course.dart'; // Import your Course model
import '../../../providers/dashboard_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../providers/favorite_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/user_provider.dart';
import '../../courses/presentation/module_row.dart';
import '../data/course_repository.dart';

/// Same gradient as HomeScreen
const LinearGradient _kDashboardBgGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF020617),
    Color(0xFF0F172A),
  ],
);

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({
    super.key,
    required this.courseId,
    this.userId,
  });

  final String courseId;
  final String? userId;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  CourseRepository? _repo;
  Course? _course; // Store course locally
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _isInCart = false;
  bool _hasInitialized = false; // Prevent multiple initializations

  Widget _glassCard({required Widget child, double opacity = 0.08}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromRGBO(255, 255, 255, opacity),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color.fromRGBO(255, 255, 255, 0.12),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  void _subscribeToCourse(BuildContext context, Course course) {
    SubscriptionController.instance.setPurchaseContext(
      courseId: course.id,
      courseTitle: course.title,
      amount: course.price,
    );
    context.push('/dashboard/subscription/summary');
  }

  void _toggleFavorite(BuildContext context) {
    if (_course == null) return;

    final favoriteProvider = context.read<FavoriteProvider>();
    final userProvider = context.read<UserProvider>();

    // Check if user is logged in
    if (userProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to add favorites'),
          backgroundColor: Color(0xFF38BDF8),
        ),
      );
      return;
    }

    favoriteProvider.toggleFavorite(_course!.id).then((_) {
      setState(() {
        _isFavorite = favoriteProvider.isFavorite(_course!.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? 'Added to favorites' : 'Removed from favorites',
          ),
          backgroundColor: _isFavorite ? const Color(0xFF38BDF8) : Colors.grey,
        ),
      );
    }).catchError((e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _addToCart(BuildContext context) {
    if (_course == null) return;

    final cartProvider = context.read<CartProvider>();
    final userProvider = context.read<UserProvider>();

    // Check if user is logged in
    if (userProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to add to cart'),
          backgroundColor: Color(0xFF38BDF8),
        ),
      );
      return;
    }

    // Check if already in cart
    if (cartProvider.isInCart(_course!.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course already in cart'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Add to cart
    cartProvider.addToCart(
      courseId: _course!.id,
      title: _course!.title,
      price: _course!.price,
      thumbnailUrl: _course!.thumbnailUrl,
    ).then((_) {
      setState(() {
        _isInCart = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to cart'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    }).catchError((e) {
      print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _goToCart(BuildContext context) {
    context.go('/dashboard/cart');
  }

  Future<void> _loadCourse() async {
    if (_hasInitialized) return; // Prevent multiple loads

    setState(() {
      _isLoading = true;
    });

    try {
      _repo ??= CourseRepositoryFactory.getInstance(
        context: context,
        userId: widget.userId,
      );

      final course = await _repo!.getCourseById(widget.courseId);

      if (mounted) {
        setState(() {
          _course = course;
          _isLoading = false;
          _hasInitialized = true;
        });

        // Update favorite and cart status after course is loaded
        _updateFavoriteAndCartStatus();
      }
    } catch (e) {
      print('Error loading course: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasInitialized = true;
        });
      }
    }
  }

  void _updateFavoriteAndCartStatus() {
    if (_course == null) return;

    final favoriteProvider = context.read<FavoriteProvider>();
    final cartProvider = context.read<CartProvider>();

    if (mounted) {
      setState(() {
        _isFavorite = favoriteProvider.isFavorite(_course!.id);
        _isInCart = cartProvider.isInCart(_course!.id);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Load course data once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCourse();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update status when providers change
    _updateFavoriteAndCartStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: _kDashboardBgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Course Details',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            // Favorite Icon
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.white,
              ),
              onPressed: _course != null ? () => _toggleFavorite(context) : null,
              tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
            ),
            // Cart Icon
            Stack(
              children: [
                IconButton(
                  icon: Icon(
                    _isInCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                    color: _isInCart ? Colors.green : Colors.white,
                  ),
                  onPressed: _course != null
                      ? () {
                    if (_isInCart) {
                      _goToCart(context);
                    } else {
                      _addToCart(context);
                    }
                  }
                      : null,
                  tooltip: _isInCart ? 'Go to cart' : 'Add to cart',
                ),
                Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    if (cartProvider.itemCount == 0) return const SizedBox();
                    return Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${cartProvider.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
        )
            : _course == null
            ? const Center(
          child: Text(
            'Failed to load course',
            style: TextStyle(color: Colors.white),
          ),
        )
            : Consumer<DashboardProvider>(
          builder: (context, dashboardProvider, _) {
            final stats = dashboardProvider.dashboardStats;

            final courseStats = stats?.courseStats
                ?.where((s) => s.courseId.toString() == _course!.id)
                .toList()
                .firstOrNull;

            final double progressPercent =
            (courseStats?.progressPercent ?? _course!.progressPercent).toDouble();
                _course!.progressPercent;

            return _buildCourseContent(progressPercent);
          },
        ),
      ),
    );
  }

  Widget _buildCourseContent(double progressPercent) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        /// Thumbnail
        GestureDetector(
          onTap: () {
            if (_course!.isSubscribed) {
              final firstUnlocked = _course!.modules
                  .firstWhere((m) => !(m.isLocked ?? true),
                  orElse: () => _course!.modules.first);
              context.go(
                '/dashboard/courses/${_course!.id}/module/${firstUnlocked.id}',
                extra: {'userId': widget.userId},
              );
            } else {
              if (_course!.modules.isNotEmpty) {
                final firstModule = _course!.modules.first;
                context.go(
                  '/dashboard/courses/${_course!.id}/module/${firstModule.id}',
                  extra: {'userId': widget.userId},
                );
              }
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  _course!.thumbnailUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: const Color(0xFF1E293B),
                      child: const Center(
                        child: Icon(
                          Icons.school,
                          size: 60,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    _course!.isSubscribed ? Icons.play_arrow : Icons.lock,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                if (!_course!.isSubscribed)
                  Positioned(
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Preview available',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        /// Course Info
        _glassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _course!.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _course!.description,
                  style: const TextStyle(color: Colors.white70),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Progress only for subscribed users
                if (_course!.isSubscribed) ...[
                  Text(
                    'Progress: ${progressPercent.toDouble().round()}%',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                /// Subscribe / Start Button
                SizedBox(
                  width: double.infinity,
                  child: _course!.isSubscribed
                      ? FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                    ),
                    onPressed: () {
                      final firstUnlocked = _course!.modules
                          .firstWhere(
                            (m) => !(m.isLocked ?? true),
                        orElse: () => _course!.modules.first,
                      );
                      context.go(
                        '/dashboard/courses/${_course!.id}/module/${firstUnlocked.id}',
                        extra: {'userId': widget.userId},
                      );
                    },
                    child: const Text('Start Learning'),
                  )
                      : FilledButton.tonal(
                    onPressed: () {
                      _subscribeToCourse(context, _course!);
                    },
                    child: const Text('Buy Full Course'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        /// Modules Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Modules',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (!_course!.isSubscribed)
              TextButton(
                onPressed: () => _subscribeToCourse(context, _course!),
                child: const Text(
                  'Subscribe to unlock all',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        /// Modules List
        ..._course!.modules.map((module) {
          final bool isLocked = module.isLocked ?? true;
          String lockReasonText = '';
          if (isLocked) {
            lockReasonText = _course!.isSubscribed
                ? 'Complete previous module'
                : 'Subscribe to unlock';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _glassCard(
              child: ModuleRow(
                module: module,
                titleColor: Colors.white,
                subtitleColor: Colors.white70,
                lockedTextColor: const Color(0xFF38BDF8),
                isLocked: isLocked,
                lockReason: lockReasonText,
                onPlay: isLocked
                    ? null
                    : () {
                  context.go(
                    '/dashboard/courses/${_course!.id}/module/${module.id}',
                    extra: {'userId': widget.userId},
                  );
                },
              ),
            ),
          );
        }).toList(),

        // Preview info for unsubscribed users
        if (!_course!.isSubscribed && _course!.modules.isNotEmpty)
          _glassCard(
            opacity: 0.05,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.visibility,
                    color: const Color(0xFF38BDF8),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'First module preview available. Subscribe for full access.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 32),
      ],
    );
  }
}