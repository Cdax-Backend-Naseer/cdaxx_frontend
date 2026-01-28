import 'package:cdax_app/providers/cart_provider.dart';
import 'package:cdax_app/providers/favorite_provider.dart';
import 'package:cdax_app/providers/module_provider.dart';
import 'package:cdax_app/services/cart_service.dart';
import 'package:cdax_app/services/favorite_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/assessment_provider.dart';
import 'providers/assessment_result_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/placement_provider.dart';
import 'providers/user_provider.dart';
import 'screens/profile/application/profile_provider.dart';

/// CDAX App Root
///
/// Uses declarative navigation with GoRouter and applies the shared theme.
class CdaxApp extends StatelessWidget {
  const CdaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(),
          lazy: false, // Force immediate creation
        ),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => AssessmentProvider()),
        ChangeNotifierProvider(create: (_) => AssessmentResultProvider()),
        ChangeNotifierProvider(create: (_) => PlacementProvider()),
        ChangeNotifierProvider(create: (_) => ModuleProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(
          create: (context) => FavoriteProvider(FavoriteService()),
        ),
        ChangeNotifierProvider(
          create: (context) => CartProvider(CartService()),
        ),
      ],
      child: _AppInitializer(),
    );
  }
}

class _AppInitializer extends StatefulWidget {
  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    // Initialize immediately when widget is created
    _initializationFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    print('🔄 Initializing app state...');

    // We need to wait for the widget tree to be ready
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    // Get the UserProvider instance
    final userProvider = context.read<UserProvider>();

    // Initialize authentication state (restores session from storage)
    await userProvider.initialize();

    print('🎯 App initialization complete');
    print('   ├─ User authenticated: ${userProvider.isAuthenticated}');
    print('   ├─ User ID: ${userProvider.userId}');
    print('   ├─ User Email: ${userProvider.userEmail}');

    // If user is authenticated, initialize other providers
    if (userProvider.isAuthenticated && userProvider.userId != null) {
      print('🔄 Initializing user-specific providers...');

      // Initialize FavoriteProvider
      final favoriteProvider = context.read<FavoriteProvider>();
      favoriteProvider.initialize(userProvider.userId!);

      // Initialize CartProvider
      final cartProvider = context.read<CartProvider>();
      cartProvider.initialize(userProvider.userId!);

      // Initialize ProfileProvider
      final profileProvider = context.read<ProfileProvider>();
      await profileProvider.fetchProfile();

      print('✅ User-specific providers initialized');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSplashScreen();
        }

        if (snapshot.hasError) {
          print('❌ App initialization error: ${snapshot.error}');
          return _buildErrorScreen(snapshot.error.toString());
        }

        return Consumer2<UserProvider, DashboardProvider>(
          builder: (context, userProvider, dashboardProvider, child) {
            // Sync authentication state
            if (dashboardProvider.isAuthenticated != userProvider.isAuthenticated ||
                dashboardProvider.currentUserId != userProvider.currentUser?.id) {

              WidgetsBinding.instance.addPostFrameCallback((_) {
                dashboardProvider.setAuthenticationContext(
                  isAuthenticated: userProvider.isAuthenticated,
                  userId: userProvider.currentUser?.id,
                );
              });
            }

            final GoRouter router = AppRouter.router;

            return MaterialApp.router(
              title: 'CDAX',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              routerConfig: router,
            );
          },
        );
      },
    );
  }

  Widget _buildSplashScreen() {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 100,
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text(
                'Restoring your session...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 50),
              const SizedBox(height: 20),
              const Text(
                'App Initialization Failed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Error: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Try to reinitialize
                  setState(() {
                    _initializationFuture = _initializeApp();
                  });
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}