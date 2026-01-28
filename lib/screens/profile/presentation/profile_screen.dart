import 'dart:convert';
import 'package:cdax_app/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../models/dashboard/dashboard_stats_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/favorite_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../services/http_service.dart';
import '../../../services/secure_storage_service.dart';
import '../application/profile_provider.dart';
import '../widgets/streak_display.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  const ProfileScreen({super.key, this.onNavigateToTab});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingOut = false;
  bool _isInitializing = true;
  bool _hasTokenError = false;
  bool _userProviderInitialized = false;

  @override
  void initState() {
    super.initState();
    print('🔄 ProfileScreen.initState() called');

    // Wait for UserProvider to initialize first
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _waitForUserProvider();
      await _initializeApp();
    });
  }

  Future<void> _waitForUserProvider() async {
    print('⏳ ProfileScreen: Waiting for UserProvider to initialize...');

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Wait for UserProvider to finish loading
    int attempts = 0;
    while (userProvider.isLoading && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
      print('   ├─ Waiting... (attempt $attempts)');
    }

    // Give it a bit more time for auth state to settle
    await Future.delayed(const Duration(milliseconds: 300));

    _userProviderInitialized = true;
    print('✅ ProfileScreen: UserProvider is ready');
    print('   ├─ isAuthenticated: ${userProvider.isAuthenticated}');
    print('   ├─ userEmail: ${userProvider.userEmail}');
  }

  Future<void> _checkTokenValidity() async {
    print('🔍 ProfileScreen._checkTokenValidity()');

    final storage = SecureStorageService.instance;
    final token = await storage.getJWTToken();

    print('   ├─ Token exists: ${token != null}');
    print('   ├─ Token length: ${token?.length ?? 0}');

    if (token == null || token.isEmpty) {
      print('❌ No token found in storage');
      setState(() {
        _hasTokenError = true;
      });
    } else {
      // Check if it's a valid JWT
      final parts = token.split('.');
      print('   ├─ Token parts: ${parts.length}');

      if (parts.length != 3) {
        print('❌ Token is not valid JWT format');
        setState(() {
          _hasTokenError = true;
        });
      }
    }
  }

  Future<void> _initializeApp() async {
    print('🔄 ProfileScreen: Starting initialization...');

    if (!_userProviderInitialized) {
      print('❌ UserProvider not initialized yet');
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // First check if user is authenticated
    if (!userProvider.isAuthenticated) {
      print('❌ User is not authenticated in UserProvider');

      // Check if we have a token anyway
      final token = await SecureStorageService.instance.getJWTToken();
      if (token != null) {
        print('⚠️ We have a token but UserProvider says not authenticated');
        print('   ├─ This suggests UserProvider initialization failed');

        // Try to manually re-initialize UserProvider
        await userProvider.initialize();

        if (userProvider.isAuthenticated) {
          print('✅ UserProvider re-initialization succeeded');
        } else {
          print('❌ UserProvider re-initialization failed');
          setState(() {
            _hasTokenError = true;
          });
          return;
        }
      } else {
        print('❌ No token found, user needs to login');
        setState(() {
          _hasTokenError = true;
        });
        return;
      }
    }

    await _debugAuthState();
    await _initializeData();
    _initializeUserServices();

    setState(() {
      _isInitializing = false;
    });
  }

  Future<void> _debugAuthState() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    print('\n🔍 ProfileScreen Auth Debug:');
    print('   ├─ isAuthenticated: ${userProvider.isAuthenticated}');
    print('   ├─ currentUser: ${userProvider.currentUser?.email}');
    print('   ├─ userEmail getter: ${userProvider.userEmail}');
    print('   ├─ userId: ${userProvider.userId}');

    // Debug secure storage
    final storage = SecureStorageService.instance;
    final token = await storage.getJWTToken();
    final userData = await storage.getUserData();
    print('   ├─ JWT Token in storage: ${token != null ? "EXISTS (${token.length} chars)" : "NULL"}');
    print('   ├─ User Data in storage: ${userData != null ? "EXISTS" : "NULL"}');

    userProvider.debugState();
  }

  Future<void> _initializeData() async {
    print('🔍 ProfileScreen: Initializing profile data...');

    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Check if we already have profile data
      if (profileProvider.profile.email.isNotEmpty) {
        print('✅ Profile already has data: ${profileProvider.profile.email}');
        return;
      }

      // Try to fetch fresh data from API
      await _fetchProfileFromAPI();

    } catch (e) {
      print('❌ Error in _initializeData: $e');
    }
  }

  Future<void> _fetchProfileFromAPI() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    print('🌐 ProfileScreen: Fetching profile from API...');

    // Double-check authentication
    if (!userProvider.isAuthenticated) {
      print('❌ Cannot fetch profile - user not authenticated');
      return;
    }

    try {
      await profileProvider.fetchProfile();

      if (profileProvider.error != null) {
        print('❌ Profile fetch failed: ${profileProvider.error}');

        final error = profileProvider.error!.toLowerCase();

        // Check for session/authentication errors
        if (error.contains('session') ||
            error.contains('expired') ||
            error.contains('unauthorized') ||
            error.contains('401') ||
            error.contains('authenticate')) {

          print('⚠️ Authentication error detected in profile fetch');

          // Clear the error from provider
          profileProvider.clearError();

          // Update local state
          setState(() {
            _hasTokenError = true;
          });

          // Force logout from UserProvider
          await userProvider.logout();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Session expired. Please login again'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'Login',
                  textColor: Colors.white,
                  onPressed: () => context.go('/login'),
                ),
              ),
            );
          }
        } else {
          // Show other errors
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Profile error: ${profileProvider.error}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        print('✅ Profile fetched successfully');
        profileProvider.debugProfile();
      }
    } catch (e) {
      print('❌ Exception fetching profile: $e');
    }
  }

  void _initializeUserServices() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      final favoriteProvider = context.read<FavoriteProvider>();
      final cartProvider = context.read<CartProvider>();

      final userId = userProvider.userId;

      if (userId != null && userId.isNotEmpty) {
        // Initialize favorites and cart with user ID
        favoriteProvider.initialize(userId);
        cartProvider.initialize(userId);
        print('✅ Initialized cart & favorites for user: $userId');
      } else {
        print('⚠️ No user ID available for cart/favorites initialization');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If token error, show login prompt immediately
    if (_hasTokenError) {
      return _buildTokenErrorScreen();
    }

    return Consumer4<ProfileProvider, DashboardProvider, FavoriteProvider, CartProvider>(
      builder: (context, profileProvider, dashboardProvider, favoriteProvider, cartProvider, child) {
        final profile = profileProvider.profile;

        // Debug on every build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print('\n👤 ProfileScreen Build - Profile State:');
          print('   ├─ isLoading: ${profileProvider.isLoading}');
          print('   ├─ error: ${profileProvider.error}');
          print('   ├─ firstName: "${profile.firstName}"');
          print('   ├─ lastName: "${profile.lastName}"');
          print('   ├─ email: "${profile.email}"');
          print('   ├─ phone: "${profile.phoneNumber}"');
          print('   ├─ hasData: ${profile.email.isNotEmpty}');
        });

        // Show loading/error states
        if (_isInitializing || profileProvider.isLoading) {
          return _buildLoadingScreen();
        }

        if (profileProvider.error != null) {
          return _buildErrorScreen(profileProvider.error!);
        }

        if (profile.email.isEmpty) {
          return _buildEmptyProfileScreen();
        }

        final initials = profile.name.isNotEmpty
            ? profile.name
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            : '?';

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Profile',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  print('🔄 Manual refresh triggered');
                  await _fetchProfileFromAPI();
                },
                tooltip: 'Refresh Profile',
              ),
              // Quick access to cart with badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () => context.go('/dashboard/cart'),
                    tooltip: 'Shopping Cart',
                  ),
                  if (cartProvider.itemCount > 0)
                    Positioned(
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
                    ),
                ],
              ),
              // Quick access to favorites
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite),
                    onPressed: () => context.go('/dashboard/favorites'),
                    tooltip: 'My Favorites',
                  ),
                  if (favoriteProvider.favoriteCount > 0)
                    Positioned(
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
                          '${favoriteProvider.favoriteCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: _isLoggingOut
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF38BDF8),
                ),
                SizedBox(height: 16),
                Text(
                  'Logging out...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
              : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile header
              _buildProfileHeader(profile, initials),
              const SizedBox(height: 16),

              // Quick Stats Row
              _buildQuickStatsRow(favoriteProvider, cartProvider),
              const SizedBox(height: 16),

              // Enrolled courses card
              _buildEnrolledCoursesCard(context, dashboardProvider),
              const SizedBox(height: 16),

              // Streak display
              const StreakDisplay(),
              const SizedBox(height: 16),

              // Settings menu
              _buildSettingsMenu(
                context,
                profileProvider,
                profile,
                favoriteProvider,
                cartProvider,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTokenErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Session Expired',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your session has expired or you need to login again.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Go to Login'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Retry initialization
                  setState(() {
                    _hasTokenError = false;
                    _isInitializing = true;
                  });
                  _initializeApp();
                },
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Keep all your existing UI methods (_buildLoadingScreen, _buildErrorScreen, etc.)
  // They should remain the same as in your original code...

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF38BDF8),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading profile...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _userProviderInitialized ? 'Fetching data...' : 'Initializing UserProvider...',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Profile Error',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _isInitializing = true;
                  });
                  await _initializeData();
                  setState(() {
                    _isInitializing = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Retry'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text(
                  'Go to Login',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyProfileScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                size: 64,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Profile Data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your profile data could not be loaded',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _isInitializing = true;
                  });
                  await _initializeData();
                  setState(() {
                    _isInitializing = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Load Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow(FavoriteProvider favoriteProvider, CartProvider cartProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.favorite,
            iconColor: Colors.red,
            label: 'Favorites',
            value: favoriteProvider.favoriteCount.toString(),
            onTap: () => context.go('/dashboard/favorites'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.shopping_cart,
            iconColor: const Color(0xFF38BDF8),
            label: 'Cart',
            value: cartProvider.itemCount.toString(),
            onTap: () => context.go('/dashboard/cart'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile profile, String initials) {
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFF38BDF8),
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name.isNotEmpty ? profile.name : 'No Name',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.email.isNotEmpty ? profile.email : 'No Email',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  if (profile.phoneNumber.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      profile.phoneNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Chip(
              label: Text(
                profile.subscribed ? 'Pro' : 'Free',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: profile.subscribed
                  ? const Color(0xFF22C55E)
                  : const Color(0xFF64748B),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrolledCoursesCard(BuildContext context, DashboardProvider dashboardProvider) {
    // Get enrolled courses from dashboard provider
    final enrolledCourses = dashboardProvider.enrolledCourses;
    final isLoading = dashboardProvider.isLoadingUser;

    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: enrolledCourses.isNotEmpty
            ? () {
          showModalBottomSheet(
            context: context,
            backgroundColor: const Color(0xFF1E293B),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            builder: (ctx) => _EnrolledCoursesSheet(courses: enrolledCourses),
          );
        }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.school, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Enrolled Courses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF38BDF8),
                      ),
                    )
                  else if (enrolledCourses.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${enrolledCourses.length}',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (isLoading)
                Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: Text(
                    'Loading courses...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                )
              else if (enrolledCourses.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No courses enrolled yet',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Browse courses to get started',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: enrolledCourses.take(3).map((course) {
                    final stats = dashboardProvider.dashboardStats;
                    CourseStat? courseStats;
                    if (stats?.courseStats != null) {
                      try {
                        courseStats = stats!.courseStats.firstWhere(
                              (stat) => stat.courseId.toString() == course.id.toString(),
                        );
                      } catch (e) {
                        courseStats = null;
                      }
                    }

                    final progressPercent = courseStats?.progressPercent ?? course.progressPercent?.round() ?? 0;

                    return Padding(
                      padding: const EdgeInsets.only(left: 36, bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              course.title ?? 'Untitled Course',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$progressPercent%',
                            style: TextStyle(
                              color: progressPercent >= 100
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFF38BDF8),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              if (enrolledCourses.length > 3)
                Padding(
                  padding: const EdgeInsets.only(left: 36, top: 4),
                  child: Text(
                    '+ ${enrolledCourses.length - 3} more courses',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsMenu(
      BuildContext context,
      ProfileProvider profileProvider,
      UserProfile profile,
      FavoriteProvider favoriteProvider,
      CartProvider cartProvider,
      ) {
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Learning Section
          _buildSectionHeader('Learning'),
          _buildMenuItem(
            icon: Icons.school,
            title: 'My Courses',
            onTap: () => context.push('/dashboard/courses'),
          ),
          _buildMenuItem(
            icon: Icons.favorite,
            title: 'My Favorites',
            badge: favoriteProvider.favoriteCount > 0 ? '${favoriteProvider.favoriteCount}' : null,
            onTap: () => context.go('/dashboard/favorites'),
          ),
          _buildMenuItem(
            icon: Icons.bookmark,
            title: 'Saved Content',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Saved content coming soon'),
                  backgroundColor: Color(0xFF38BDF8),
                ),
              );
            },
          ),
          const Divider(height: 1, color: Colors.white12),

          // Shopping Section
          _buildSectionHeader('Shopping'),
          _buildMenuItem(
            icon: Icons.shopping_cart,
            title: 'Shopping Cart',
            badge: cartProvider.itemCount > 0 ? '${cartProvider.itemCount}' : null,
            onTap: () => context.go('/dashboard/cart'),
          ),
          _buildMenuItem(
            icon: Icons.receipt_long,
            title: 'Order History',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order history coming soon'),
                  backgroundColor: Color(0xFF38BDF8),
                ),
              );
            },
          ),
          const Divider(height: 1, color: Colors.white12),

          // Account Section
          _buildSectionHeader('Account'),
          _buildMenuItem(
            icon: Icons.edit,
            title: 'Edit Profile',
            onTap: () async {
              // Navigate to edit screen
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfileEditScreen(initial: profile),
                ),
              );

              // After editing, refresh the profile
              if (mounted) {
                await profileProvider.fetchProfile();
              }
            },
          ),
          _buildMenuItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings coming soon'),
                  backgroundColor: Color(0xFF38BDF8),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.workspace_premium,
            title: 'Certifications',
            onTap: () => context.push('/dashboard/certifications'),
          ),
          _buildMenuItem(
            icon: Icons.credit_card,
            title: 'Payment',
            onTap: () => context.push('/dashboard/subscription/methods'),
          ),
          _buildMenuItem(
            icon: Icons.work,
            title: 'Placement',
            onTap: () => context.push('/dashboard/placement/eligibility'),
          ),
          const Divider(height: 1, color: Colors.white12),

          // Support Section
          _buildSectionHeader('Support'),
          _buildMenuItem(
            icon: Icons.help,
            title: 'Help & Support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help center coming soon'),
                  backgroundColor: Color(0xFF38BDF8),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy Policy coming soon'),
                  backgroundColor: Color(0xFF38BDF8),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.description,
            title: 'Terms of Service',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Terms of service coming soon'),
                  backgroundColor: Color(0xFF38BDF8),
                ),
              );
            },
          ),
          const Divider(height: 1, color: Colors.white12),

          // Logout
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () => _showLogoutDialog(context),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? badge,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.redAccent : Colors.white,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDestructive ? Colors.redAccent : Colors.white,
              ),
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDestructive ? Colors.redAccent : Colors.white70,
      ),
      onTap: onTap,
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Logout', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to logout?\n\nYour session will be cleared from this device.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && context.mounted) {
      await _performLogout(context);
    }
  }

  Future<void> _performLogout(BuildContext context) async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final favoriteProvider = Provider.of<FavoriteProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final httpService = HttpService();

      print('🚪 Performing logout...');

      // Clear all user data
      await userProvider.logout();

      // Clear JWT token from HttpService
      await httpService.clearJWTToken();

      // Clear provider data
      favoriteProvider.clear();
      cartProvider.clear();

      if (context.mounted) {
        // Navigate to login screen
        print('✅ Logout successful, redirecting to login');
        context.go('/login');
      }
    } catch (e) {
      print('❌ Logout error: $e');

      if (context.mounted) {
        setState(() {
          _isLoggingOut = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class _EnrolledCoursesSheet extends StatelessWidget {
  final List<dynamic> courses;

  const _EnrolledCoursesSheet({required this.courses});

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    final stats = dashboardProvider.dashboardStats;

    return SafeArea(
      child: SizedBox(
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Enrolled Courses',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
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
                      '${courses.length}',
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: courses.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school,
                      size: 60,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No courses enrolled yet',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Browse courses to get started',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: courses.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 20,
                  color: Colors.white12,
                ),
                itemBuilder: (context, i) {
                  final course = courses[i];

                  // Get course progress
                  CourseStat? courseStats;
                  if (stats?.courseStats != null) {
                    try {
                      courseStats = stats!.courseStats.firstWhere(
                            (stat) => stat.courseId.toString() == course.id.toString(),
                      );
                    } catch (e) {
                      courseStats = null;
                    }
                  }

                  final progressPercent = courseStats?.progressPercent ?? course.progressPercent?.round() ?? 0;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(course.thumbnailUrl ?? ''),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: course.thumbnailUrl == null
                          ? Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.school,
                          color: Colors.white,
                          size: 24,
                        ),
                      )
                          : null,
                    ),
                    title: Text(
                      course.title ?? 'Untitled Course',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressPercent / 100,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            color: progressPercent >= 100
                                ? const Color(0xFF22C55E)
                                : const Color(0xFF38BDF8),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Progress $progressPercent%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      final currentUserId = userProvider.currentUser?.id?.toString();

                      context.push(
                        '/dashboard/courses/${course.id}',
                        extra: {'userId': currentUserId},
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}