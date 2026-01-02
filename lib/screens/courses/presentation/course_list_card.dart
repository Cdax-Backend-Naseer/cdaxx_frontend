import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../models/dashboard/dashboard_stats_model.dart';

class CourseListCard extends StatelessWidget {
  const CourseListCard({
    super.key,
    required this.course,
  });

  final dynamic course;

  // Safe getters
  String get _id => course.id?.toString() ?? '';
  String get _title => course.title?.toString() ?? 'Untitled Course';
  String get _description => course.description?.toString() ?? '';
  String get _thumbnailUrl => course.thumbnailUrl?.toString() ?? '';

  bool get _isSubscribed {
    if (course.isSubscribed != null) return course.isSubscribed;
    if (course.purchased != null) return course.purchased;
    return false;
  }

  // Helper functions for transparent colors
  Color _whiteWithOpacity(double opacity) {
    return Color.fromRGBO(255, 255, 255, opacity);
  }

  Color _blueWithOpacity(double opacity) {
    return Color.fromRGBO(56, 189, 248, opacity);
  }

  // Mobile responsive helper
  T _mobileResponsiveValue<T>({
    required T small,
    required T medium,
    required T large,
    required BuildContext context,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return small;     // Small phones (iPhone SE, etc.)
    if (width < 400) return medium;    // Medium phones
    return large;                       // Large phones/tablets
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width < 400;
    final isLandscape = size.width > size.height;

    // Responsive values for mobile
    final double cardPadding = _mobileResponsiveValue(
      context: context,
      small: 10,
      medium: 12,
      large: 14,
    );

    final double thumbnailWidth = _mobileResponsiveValue(
      context: context,
      small: 80,
      medium: 90,
      large: isLandscape ? 120 : 100,
    );

    final double thumbnailHeight = _mobileResponsiveValue(
      context: context,
      small: 48,
      medium: 54,
      large: isLandscape ? 70 : 60,
    );

    final double spacing = _mobileResponsiveValue(
      context: context,
      small: 6,
      medium: 8,
      large: 10,
    );

    final double borderRadius = _mobileResponsiveValue(
      context: context,
      small: 10,
      medium: 12,
      large: 14,
    );

    final double titleFontSize = _mobileResponsiveValue(
      context: context,
      small: 13,
      medium: 14,
      large: 15,
    );

    final double descriptionFontSize = _mobileResponsiveValue(
      context: context,
      small: 10,
      medium: 11,
      large: 12,
    );

    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        final stats = dashboardProvider.dashboardStats;

        // Find course stats
        CourseStat? courseStats;
        if (stats?.courseStats != null && _id.isNotEmpty) {
          try {
            courseStats = stats!.courseStats!.firstWhere(
                  (stat) => stat.courseId.toString() == _id,
            );
          } catch (e) {
            debugPrint('⚠️ CourseListCard: Error finding stats for course $_id: $e');
          }
        }

        // Safe conversion to double for progress
        final double progressPercent = ((courseStats?.progressPercent ??
            (course.progressPercent ?? 0))
            .toDouble())
            .clamp(0.0, 100.0);
        final double progressValue = progressPercent / 100.0;

        // Colors for mobile glass theme
        final Color cardColor = _whiteWithOpacity(0.05);
        final Color borderColor = _isSubscribed
            ? _blueWithOpacity(0.3)
            : _whiteWithOpacity(0.12);
        final Color textColor = Colors.white;
        final Color secondaryTextColor = _whiteWithOpacity(0.7);
        final Color progressColor = const Color(0xFF38BDF8);

        return InkWell(
          onTap: () => context.go('/dashboard/courses/$_id'),
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: cardColor,
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            margin: EdgeInsets.symmetric(
              horizontal: _mobileResponsiveValue(
                context: context,
                small: 12,
                medium: 14,
                large: 16,
              ),
              vertical: _mobileResponsiveValue(
                context: context,
                small: 4,
                medium: 6,
                large: 8,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail Container
                  Container(
                    width: thumbnailWidth,
                    height: thumbnailHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius - 2),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF475569),
                          Color(0xFF334155),
                        ],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(borderRadius - 2),
                      child: Image.network(
                        _thumbnailUrl,
                        width: thumbnailWidth,
                        height: thumbnailHeight,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: thumbnailWidth,
                          height: thumbnailHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(borderRadius - 2),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF64748B),
                                Color(0xFF475569),
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.play_circle_outline,
                            color: _whiteWithOpacity(0.8),
                            size: _mobileResponsiveValue(
                              context: context,
                              small: 20,
                              medium: 22,
                              large: 24,
                            ),
                          ),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: thumbnailWidth,
                            height: thumbnailHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(borderRadius - 2),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF475569),
                                  Color(0xFF334155),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  SizedBox(width: spacing),

                  // Content Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _title,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                                maxLines: isSmallScreen ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!_isSubscribed && !isSmallScreen)
                              Container(
                                margin: EdgeInsets.only(left: 4),
                                padding: EdgeInsets.symmetric(
                                  horizontal: _mobileResponsiveValue(
                                    context: context,
                                    small: 4,
                                    medium: 6,
                                    large: 8,
                                  ),
                                  vertical: _mobileResponsiveValue(
                                    context: context,
                                    small: 1,
                                    medium: 2,
                                    large: 3,
                                  ),
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF38BDF8),
                                      Color(0xFF0EA5E9),
                                    ],
                                  ),
                                ),
                                child: Text(
                                  'Subscribe',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: _mobileResponsiveValue(
                                      context: context,
                                      small: 9,
                                      medium: 10,
                                      large: 11,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        if (!isSmallScreen) SizedBox(height: spacing / 2),

                        // Description
                        if (!isSmallScreen)
                          Text(
                            _description,
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: descriptionFontSize,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                            maxLines: isMediumScreen ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                        if (!isSmallScreen) SizedBox(height: spacing),

                        // Progress or Additional Info
                        if (_isSubscribed)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Progress Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: progressValue,
                                  backgroundColor: _whiteWithOpacity(0.1),
                                  color: progressColor,
                                  minHeight: _mobileResponsiveValue(
                                    context: context,
                                    small: 4,
                                    medium: 5,
                                    large: 6,
                                  ),
                                ),
                              ),
                              SizedBox(height: _mobileResponsiveValue(
                                context: context,
                                small: 2,
                                medium: 3,
                                large: 4,
                              )),
                              Text(
                                '${progressPercent.round()}% complete',
                                style: TextStyle(
                                  color: progressColor,
                                  fontSize: _mobileResponsiveValue(
                                    context: context,
                                    small: 9,
                                    medium: 10,
                                    large: 11,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}