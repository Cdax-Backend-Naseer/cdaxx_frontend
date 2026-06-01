import 'dart:ui';

import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../../courses/presentation/course_list_screen.dart';
import 'modules_screen.dart';
import '../../support/presentation/support_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../download/downloads_screen.dart'; // ADD THIS IMPORT

/// Gradient background constants from login screen
const LinearGradient _kDashboardBgGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF020617), // Rich dark blue/navy
    Color(0xFF0F172A), // Slightly lighter dark blue
  ],
);

/// DashboardScreen with BottomNavigation + AutomaticKeepAlive
/// - Preserves state of each tab
/// - Prevents unnecessary HomeScreen rebuilds
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (_currentIndex == index) return;

    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    print('📱 DashboardScreen: Building - Current index: $_currentIndex');

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Container(
        decoration: const BoxDecoration(gradient: _kDashboardBgGradient),
        child: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: _onPageChanged,
          children: [
            // Tab 0: Home
            _KeepAlivePage(
              child: HomeScreen(
                onNavigateToTab: _onTap,
              ),
            ),
            // Tab 1: Courses
            _KeepAlivePage(
              child: CourseListScreen(
                onNavigateToTab: _onTap,
              ),
            ),
            // Tab 2: Modules
            _KeepAlivePage(
              child: ModulesScreen(
                onNavigateToTab: _onTap,
              ),
            ),
            // Tab 3: Downloads (NEW - replaced Support)
            _KeepAlivePage(
              child: const DownloadsScreen(),
            ),
            // Tab 4: Profile
            _KeepAlivePage(
              child: ProfileScreen(
                onNavigateToTab: _onTap,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildGlassBottomNavBar(context),
    );
  }

  Widget _buildGlassBottomNavBar(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38BDF8).withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: const Color(0xFF38BDF8),
            unselectedItemColor: Colors.white.withOpacity(0.6),
            selectedLabelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF38BDF8),
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.6),
            ),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: [
              // Tab 0: Home
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _currentIndex == 0
                        ? const Color(0xFF38BDF8).withOpacity(0.15)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    _currentIndex == 0 ? Icons.home : Icons.home_outlined,
                    size: 24,
                  ),
                ),
                label: 'Home',
              ),
              // Tab 1: Courses
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _currentIndex == 1
                        ? const Color(0xFF38BDF8).withOpacity(0.15)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    _currentIndex == 1
                        ? Icons.menu_book
                        : Icons.menu_book_outlined,
                    size: 24,
                  ),
                ),
                label: 'Courses',
              ),
              // Tab 2: Modules
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _currentIndex == 2
                        ? const Color(0xFF38BDF8).withOpacity(0.15)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    _currentIndex == 2
                        ? Icons.grid_view
                        : Icons.grid_view_outlined,
                    size: 24,
                  ),
                ),
                label: 'Modules',
              ),
              // Tab 3: Downloads (NEW)
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _currentIndex == 3
                        ? const Color(0xFF38BDF8).withOpacity(0.15)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    _currentIndex == 3
                        ? Icons.download
                        : Icons.download_outlined,
                    size: 24,
                  ),
                ),
                label: 'Downloads',
              ),
              // Tab 4: Profile
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _currentIndex == 4
                        ? const Color(0xFF38BDF8).withOpacity(0.15)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    _currentIndex == 4 ? Icons.person : Icons.person_outline,
                    size: 24,
                  ),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrapper widget that preserves state when not visible
class _KeepAlivePage extends StatefulWidget {
  final Widget child;

  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}