import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';

/// Splash screen showing logo and tagline. Auto-navigates to /login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationAndNavigate();
  }

  Future<void> _checkAuthenticationAndNavigate() async {
    print('🔄 SplashScreen: Starting authentication check');

    // Wait for initialization
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) {
      print('❌ SplashScreen: Not mounted, exiting');
      return;
    }

    print('🔄 SplashScreen: Getting UserProvider');
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    print('🔄 SplashScreen: Calling userProvider.initialize()');
    await userProvider.initialize();

    print('✅ SplashScreen: UserProvider initialized');
    print('   ├─ isAuthenticated: ${userProvider.isAuthenticated}');
    print('   ├─ currentUser: ${userProvider.currentUser?.email}');

    // Show splash for at least 3 seconds total
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) {
      print('❌ SplashScreen: Not mounted after delay, exiting');
      return;
    }

    if (userProvider.isAuthenticated) {
      print('🚀 SplashScreen: User IS authenticated, going to /dashboard');
      context.go('/dashboard');
    } else {
      print('🚀 SplashScreen: User NOT authenticated, going to /');
      print('   ├─ This should redirect to /onboarding via root route');
      context.go('/');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon(Icons.school, size: 80, color: theme.colorScheme.primary),
            // const SizedBox(height: 16),
            // Text('CDAX', style: theme.textTheme.headlineLarge),
            // const SizedBox(height: 8),
            // Text(
            //   'Learn. Grow. Excel.',
            //   style: theme.textTheme.bodyLarge?.copyWith(
            //     color: theme.colorScheme.onSurfaceVariant,
            //   ),
            // ),

            Image(image: AssetImage('assets/images/logo.png'), height: 120),
          ],
        ),
      ),
    );
  }
}