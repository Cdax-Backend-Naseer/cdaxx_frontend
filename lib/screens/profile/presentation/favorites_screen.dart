// screens/favorites/presentation/favorites_screen.dart - UPDATED VERSION
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/favorite_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../screens/courses/presentation/course_list_card.dart';
import '../../../services/course_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoading = false;
  final List<Course> _favoriteCourses = []; // Use Course type (not CourseModel)
  final CourseService _courseService = CourseService(); // Use CourseService

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFavorites();
    });
  }

  Future<void> _initializeFavorites() async {
    final userProvider = context.read<UserProvider>();
    final favoriteProvider = context.read<FavoriteProvider>();

    // Get user ID as String for FavoriteProvider
    final userId = userProvider.currentUser?.id?.toString();

    if (userId != null && userId.isNotEmpty) {
      // Initialize favorites if not already initialized
      if (!favoriteProvider.isInitialized) {
        favoriteProvider.initialize(userId);
      }

      // Load favorite courses
      await _loadFavoriteCourses();
    } else {
      print('⚠️ User ID is null or empty');
    }
  }

  Future<void> _loadFavoriteCourses() async {
    final userProvider = context.read<UserProvider>();
    final favoriteProvider = context.read<FavoriteProvider>();

    if (!favoriteProvider.isInitialized) {
      print('⚠️ Favorites not initialized yet');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get favorite course IDs
      final favoriteCourseIds = favoriteProvider.favoriteCourseIds;

      print('📊 Loading ${favoriteCourseIds.length} favorite courses');

      if (favoriteCourseIds.isEmpty) {
        setState(() {
          _favoriteCourses.clear();
          _isLoading = false;
        });
        return;
      }

      // Use CourseService to get all courses
      print('🔍 Fetching all courses from CourseService...');
      final allCoursesResponse = await _courseService.getAllCourses();

      if (allCoursesResponse.isSuccess) {
        final allCourses = allCoursesResponse.data ?? [];
        print('✅ API Success: Found ${allCourses.length} total courses');

        // Filter to get only favorite courses
        _favoriteCourses.clear();
        for (final course in allCourses) {
          if (favoriteCourseIds.contains(course.id.toString())) {
            _favoriteCourses.add(course);
          }
        }

        print('✅ Loaded ${_favoriteCourses.length} favorite courses from API');
      } else {
        print('❌ API Error: ${allCoursesResponse.errorMessage}');
        // Show empty state or handle error
      }

    } catch (e) {
      print('❌ Error loading favorite courses: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshFavorites() async {
    final favoriteProvider = context.read<FavoriteProvider>();

    if (favoriteProvider.isInitialized) {
      // Refresh favorites from API
      await favoriteProvider.refresh();
    } else {
      // Re-initialize if needed
      await _initializeFavorites();
    }

    // Reload favorite courses
    await _loadFavoriteCourses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'My Favorites',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshFavorites,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<FavoriteProvider>(
        builder: (context, favoriteProvider, child) {
          return _isLoading
              ? const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF38BDF8),
            ),
          )
              : _favoriteCourses.isEmpty
              ? _buildEmptyState(favoriteProvider)
              : _buildFavoritesList(favoriteProvider);
        },
      ),
    );
  }

  Widget _buildEmptyState(FavoriteProvider favoriteProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              favoriteProvider.favoriteCount > 0
                  ? 'Loading favorites...'
                  : 'No favorite courses yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              favoriteProvider.favoriteCount > 0
                  ? 'Please wait while we load your favorites'
                  : 'Tap the heart icon on courses to add them here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            if (favoriteProvider.favoriteCount == 0)
              ElevatedButton(
                onPressed: () {
                  context.go('/dashboard/courses');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Browse Courses'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(FavoriteProvider favoriteProvider) {
    return RefreshIndicator(
      onRefresh: _refreshFavorites,
      color: const Color(0xFF38BDF8),
      backgroundColor: const Color(0xFF0F172A),
      child: Column(
        children: [
          // Header with count
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${favoriteProvider.favoriteCount} Favorite Courses',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${favoriteProvider.favoriteCount}',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List of favorite courses
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _favoriteCourses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final course = _favoriteCourses[index];

                return CourseListCard(
                  course: course, // Pass Course object directly
                  showFavoriteIcon: true,
                  showCartIcon: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}