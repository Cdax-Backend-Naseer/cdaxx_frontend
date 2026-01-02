import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Gradient background same as BeforeSignUpScreen
const LinearGradient kBgGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF020617),
    Color(0xFF0F172A),
  ],
);

/// Course Detail Screen for Before Signup Flow
/// Shows course details with a "Continue" button that redirects to signup
class BeforeSignupCourseDetailScreen extends StatelessWidget {
  final String courseId;
  final String? courseTitle;
  final String? courseDescription;
  final String? thumbnailUrl;

  const BeforeSignupCourseDetailScreen({
    super.key,
    required this.courseId,
    this.courseTitle,
    this.courseDescription,
    this.thumbnailUrl,
  });

  // Mobile responsive helper - REMOVED THIS METHOD
  // We'll use inline calculations instead

  void _goToSignup(BuildContext context) {
    context.push('/signup');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;

    // Mock course data - replace with actual course details
    final title = courseTitle ?? 'Course Title $courseId';
    final description = courseDescription ??
        'Comprehensive course covering essential topics and practical skills. This course is designed to help you master the fundamentals and advance your career.';
    final imageUrl = thumbnailUrl ??
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSzclOCfiTUTy0lpYU1lPbvUhlpoVP9mcbE0Q&s';

    // Responsive values calculated inline
    final double horizontalPadding = isMobile ? 16 : isTablet ? 24 : 32;
    final double verticalSpacing = isMobile ? 16 : isTablet ? 20 : 24;
    final double imageHeight = isMobile ? 180 : isTablet ? 220 : 250;
    final double titleFontSize = isMobile ? 22 : isTablet ? 24 : 26;
    final double bodyFontSize = isMobile ? 14 : isTablet ? 15 : 16;
    final double cardPadding = isMobile ? 14 : isTablet ? 18 : 22;
    final double chipSpacing = isMobile ? 6 : isTablet ? 8 : 10;
    final double iconSize = isMobile ? 20 : isTablet ? 22 : 24;
    final double appBarFontSize = isMobile ? 18 : isTablet ? 20 : 22;
    final double buttonVerticalPadding = isMobile ? 14 : isTablet ? 16 : 18;
    final double buttonFontSize = isMobile ? 15 : isTablet ? 16 : 17;
    final double detailIconSize = isMobile ? 18 : isTablet ? 20 : 22;
    final double blurSigma = isMobile ? 10 : isTablet ? 12 : 14;

    Widget _buildGlassCard({required Widget child, double opacity = 0.08}) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withOpacity(0.15),
                  blurRadius: isMobile ? 15 : isTablet ? 20 : 25,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
    }

    Widget _buildDetailRow({
      required IconData icon,
      required String title,
      required String value,
    }) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: isMobile ? 10 : isTablet ? 12 : 12,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 6 : isTablet ? 8 : 10),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF38BDF8),
                size: detailIconSize,
              ),
            ),
            SizedBox(width: isMobile ? 10 : isTablet ? 12 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isMobile ? 12 : isTablet ? 13 : 14,
                    ),
                  ),
                  SizedBox(height: isMobile ? 2 : 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: isMobile ? 13 : isTablet ? 14 : 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: iconSize,
          ),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
          padding: EdgeInsets.all(isMobile ? 8 : isTablet ? 10 : 12),
        ),
        title: Text(
          'Course Details',
          style: TextStyle(
            fontSize: appBarFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        toolbarHeight: isMobile ? 56 : isTablet ? 64 : 72,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: kBgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: verticalSpacing),

                // Course Image - Responsive
                Container(
                  height: imageHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF475569),
                                Color(0xFF334155),
                              ],
                            ),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: const Color(0xFF38BDF8),
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF64748B),
                                Color(0xFF475569),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.school,
                              size: isMobile ? 48 : isTablet ? 56 : 64,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                SizedBox(height: verticalSpacing),

                // Course Title - Responsive
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: verticalSpacing / 2),

                // Course Tags - Responsive
                Wrap(
                  spacing: chipSpacing,
                  runSpacing: chipSpacing / 2,
                  children: [
                    Chip(
                      label: Text(
                        'Beginner',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: isMobile ? 11 : isTablet ? 12 : 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: Colors.green.withOpacity(0.2),
                      side: BorderSide(color: Colors.green.withOpacity(0.3)),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : isTablet ? 10 : 12,
                        vertical: isMobile ? 2 : 4,
                      ),
                    ),
                    Chip(
                      label: Text(
                        '10+ Lessons',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: isMobile ? 11 : isTablet ? 12 : 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: Colors.blue.withOpacity(0.2),
                      side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : isTablet ? 10 : 12,
                        vertical: isMobile ? 2 : 4,
                      ),
                    ),
                    Chip(
                      label: Text(
                        'Certificate',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: isMobile ? 11 : isTablet ? 12 : 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: Colors.orange.withOpacity(0.2),
                      side: BorderSide(color: Colors.orange.withOpacity(0.3)),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : isTablet ? 10 : 12,
                        vertical: isMobile ? 2 : 4,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: verticalSpacing),

                // Description Card - Responsive
                _buildGlassCard(
                  opacity: 0.1,
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About This Course',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : isTablet ? 20 : 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: isMobile ? 8 : isTablet ? 12 : 16),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: bodyFontSize,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: verticalSpacing),

                // What You'll Learn Card - Responsive
                _buildGlassCard(
                  opacity: 0.1,
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What You\'ll Learn',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : isTablet ? 20 : 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: isMobile ? 12 : isTablet ? 16 : 20),

                        ...List.generate(4, (index) {
                          final learningPoints = [
                            'Master the fundamental concepts',
                            'Build practical, real-world projects',
                            'Prepare for industry certifications',
                            'Develop problem-solving skills',
                          ];

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: isMobile ? 10 : isTablet ? 12 : 12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: const Color(0xFF38BDF8),
                                  size: isMobile ? 18 : isTablet ? 20 : 22,
                                ),
                                SizedBox(width: isMobile ? 10 : isTablet ? 12 : 12),
                                Expanded(
                                  child: Text(
                                    learningPoints[index],
                                    style: TextStyle(
                                      fontSize: bodyFontSize,
                                      color: Colors.white70,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: verticalSpacing),

                // Course Details Card - Responsive
                _buildGlassCard(
                  opacity: 0.1,
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Course Details',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : isTablet ? 20 : 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: isMobile ? 12 : isTablet ? 16 : 20),

                        _buildDetailRow(
                          icon: Icons.access_time,
                          title: 'Duration',
                          value: '4-6 Weeks',
                        ),
                        _buildDetailRow(
                          icon: Icons.school,
                          title: 'Level',
                          value: 'Beginner',
                        ),
                        _buildDetailRow(
                          icon: Icons.video_library,
                          title: 'Lessons',
                          value: '15+ Videos',
                        ),
                        _buildDetailRow(
                          icon: Icons.assignment,
                          title: 'Assignments',
                          value: '5 Practical Projects',
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: verticalSpacing * 2),
              ],
            ),
          ),
        ),
      ),

      // Bottom Continue Button - Responsive
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(horizontalPadding),
        decoration: BoxDecoration(
          gradient: kBgGradient,
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isMobile ? 8 : isTablet ? 10 : 12,
              sigmaY: isMobile ? 8 : isTablet ? 10 : 12,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withOpacity(0.15),
                    blurRadius: 15,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => _goToSignup(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: buttonVerticalPadding,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: Text(
                  'Continue to Sign Up',
                  style: TextStyle(
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}