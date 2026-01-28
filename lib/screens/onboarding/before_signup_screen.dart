import 'dart:ui';
import 'package:cdax_app/screens/courses/application/course_providers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../screens/dashboard/widgets/course_card.dart';
import '../../screens/dashboard/widgets/suggestive_learning_card.dart';
import '../../screens/dashboard/widgets/progress_card.dart';

/// Gradient background same as login screen
const LinearGradient kBgGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF020617),
    Color(0xFF0F172A),
  ],
);

class BeforeSignUpScreen extends StatelessWidget {
  const BeforeSignUpScreen({super.key});

  void _goToSignup(BuildContext context) {
    context.push('/signup');
  }

  void _goToCourseDetail(BuildContext context, dynamic course) {
    context.pushNamed(
      'beforeSignUpCourseDetail',
      pathParameters: {'courseId': course.id.toString()},
      extra: {
        'title': course.title ?? 'Course',
        'description': course.description ?? '',
        'thumbnail': course.thumbnailUrl ?? '',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive calculations
    final bool isSmallScreen = screenWidth < 360;
    final bool isMediumScreen = screenWidth >= 360 && screenWidth < 400;
    final double cardSpacing = isSmallScreen ? 8.0 : 12.0;
    final double horizontalPadding = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: kBgGradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {},
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      "Welcome!",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: isSmallScreen ? 28 : 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Explore courses and begin your learning journey.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // -----------------------------
                  // Top Suggestive Card: Start Learning Today
                  // -----------------------------
                  _buildGlassCard(
                    onTap: () => _goToSignup(context),
                    child: SuggestiveLearningCard(
                      title: "Start Learning Today",
                      description: "Discover curated learning paths crafted for beginners.",
                      imageUrl:
                      "https://img.freepik.com/free-vector/flat-design-online-college-facebook-template_23-2150581239.jpg?semt=ais_hybrid&w=740&q=80",
                      onPressed: () => _goToSignup(context),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // -----------------------------
                  // Available Courses
                  // -----------------------------
                  Text(
                    "Available Courses",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  const SizedBox(height: 12),

                  FutureBuilder(
                    future: CourseProviders.getCourseRepository().getPublicCourses(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            "Failed: ${snapshot.error}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      final courses = snapshot.data ?? [];

                      if (courses.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            "No courses available",
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      // Calculate cross axis count based on screen width
                      final crossAxisCount = screenWidth > 500 ? 3 : 2;
                      final childAspectRatio = screenWidth > 500 ? 0.8 : 0.75;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: courses.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          mainAxisSpacing: cardSpacing,
                          crossAxisSpacing: cardSpacing,
                        ),
                        itemBuilder: (context, index) {
                          final c = courses[index];
                          return _buildGlassCard(
                            onTap: () => _goToCourseDetail(context, c),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: Image.network(
                                    c.thumbnailUrl??"",
                                    height: screenHeight * 0.12, // Responsive height
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: screenHeight * 0.12,
                                        width: double.infinity,
                                        color: Colors.grey[800],
                                        child: const Center(
                                          child: Icon(
                                            Icons.school,
                                            color: Colors.grey,
                                            size: 35,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.title,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isSmallScreen ? 14 : 16,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Expanded(
                                          child: Text(
                                            c.description,
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: isSmallScreen ? 11 : 12,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // -----------------------------
                  // Placements - FIXED SECTION
                  // -----------------------------
// -----------------------------
// Placements - COMPACT FIXED SECTION
// -----------------------------
            Text(
              "Placement Opportunities",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: isSmallScreen ? 20 : 24,
              ),
            ),
            const SizedBox(height: 12),

// Compact horizontal list view
            SizedBox(
              height: isSmallScreen ? 140 : 160, // Much smaller height
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                itemBuilder: (context, index) {
                  final placements = [
                    {
                      'title': 'Software Engineer',
                      'company': 'Tech Corp',
                      'salary': '₹8-12 LPA',
                      'icon': Icons.computer,
                      'color': const Color(0xFF38BDF8),
                    },
                    {
                      'title': 'Data Analyst',
                      'company': 'Analytics Inc',
                      'salary': '₹6-10 LPA',
                      'icon': Icons.analytics,
                      'color': const Color(0xFF22D3EE),
                    },
                    {
                      'title': 'UI/UX Designer',
                      'company': 'Design Studio',
                      'salary': '₹5-9 LPA',
                      'icon': Icons.design_services,
                      'color': const Color(0xFFA855F7),
                    },
                    {
                      'title': 'Product Manager',
                      'company': 'Startup Hub',
                      'salary': '₹10-15 LPA',
                      'icon': Icons.business_center,
                      'color': const Color(0xFFF59E0B),
                    },
                  ];

                  final placement = placements[index];
                  final cardWidth = isSmallScreen ? screenWidth * 0.6 : screenWidth * 0.55;

                  return Container(
                    width: cardWidth,
                    margin: EdgeInsets.only(
                      right: index < 3 ? (isSmallScreen ? 10 : 12) : 0,
                    ),
                    child: _buildGlassCard(
                      onTap: () => _goToSignup(context),
                      child: Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Icon Container
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                              decoration: BoxDecoration(
                                color: (placement['color'] as Color).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                placement['icon'] as IconData,
                                color: placement['color'] as Color,
                                size: isSmallScreen ? 24 : 28,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 12 : 16),

                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    placement['title'] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 14 : 15,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: isSmallScreen ? 4 : 6),
                                  Text(
                                    placement['company'] as String,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: isSmallScreen ? 12 : 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: isSmallScreen ? 4 : 6),
                                  Text(
                                    placement['salary'] as String,
                                    style: TextStyle(
                                      color: placement['color'] as Color,
                                      fontSize: isSmallScreen ? 13 : 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Arrow icon
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white60,
                              size: isSmallScreen ? 16 : 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
                  // -----------------------------
                  // Certifications - FIXED SECTION
                  // -----------------------------
                  Text(
                    "Professional Certifications",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Using ListView instead of GridView for certifications
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      final certifications = [
                        {
                          'title': 'Software Engineering Fundamentals',
                          'description': 'Core programming and development practices',
                          'duration': '6 weeks',
                          'icon': Icons.code,
                        },
                        {
                          'title': 'Data Science Professional',
                          'description': 'Statistical analysis and machine learning',
                          'duration': '8 weeks',
                          'icon': Icons.science,
                        },
                        {
                          'title': 'Project Management Certified',
                          'description': 'Leadership and project delivery skills',
                          'duration': '4 weeks',
                          'icon': Icons.assignment,
                        },
                      ];

                      final cert = certifications[index];

                      return Padding(
                        padding: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
                        child: _buildGlassCard(
                          onTap: () => _goToSignup(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 12 : 14,
                              horizontal: isSmallScreen ? 12 : 16,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF38BDF8).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    cert['icon'] as IconData,
                                    color: const Color(0xFF38BDF8),
                                    size: isSmallScreen ? 20 : 24,
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 12 : 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cert['title'] as String,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isSmallScreen ? 14 : 16,
                                          color: Colors.white,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        cert['description'] as String,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: isSmallScreen ? 12 : 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        cert['duration'] as String,
                                        style: TextStyle(
                                          color: const Color(0xFF38BDF8),
                                          fontSize: isSmallScreen ? 12 : 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.white60,
                                  size: isSmallScreen ? 20 : 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // -----------------------------
                  // Assessment
                  // -----------------------------
                  Text(
                    "Assessment",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildGlassCard(
                    onTap: () => _goToSignup(context),
                    child: ProgressCard(
                      title: "General Aptitude Test",
                      progress: 0.0,
                      onTap: () => _goToSignup(context),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.1), // Responsive bottom padding
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper to create a glass-style card
  Widget _buildGlassCard({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}