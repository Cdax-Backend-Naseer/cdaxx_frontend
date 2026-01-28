import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/favorite_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../models/dashboard/dashboard_stats_model.dart';

class CourseListCard extends StatelessWidget {
  const CourseListCard({
    super.key,
    required this.course,
    this.showFavoriteIcon = true,
    this.showCartIcon = false,
  });

  final dynamic course;
  final bool showFavoriteIcon;
  final bool showCartIcon;

  // Safe getters
  String get _id => course.id?.toString() ?? '';
  String get _title => course.title?.toString() ?? 'Untitled Course';
  String get _description => course.description?.toString() ?? '';
  String get _thumbnailUrl => course.thumbnailUrl?.toString() ?? '';
  double get _price => (course.price ?? 0.0).toDouble();

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
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width < 400;
    final isLandscape = size.width > size.height;

    // Responsive values
    final double cardPadding = _mobileResponsiveValue(
      context: context,
      small: 12,
      medium: 14,
      large: 16,
    );

    final double thumbnailWidth = _mobileResponsiveValue(
      context: context,
      small: 90,
      medium: 100,
      large: isLandscape ? 140 : 120,
    );

    final double thumbnailHeight = _mobileResponsiveValue(
      context: context,
      small: 60,
      medium: 70,
      large: isLandscape ? 90 : 80,
    );

    final double borderRadius = _mobileResponsiveValue(
      context: context,
      small: 12,
      medium: 14,
      large: 16,
    );

    return Consumer3<DashboardProvider, FavoriteProvider, CartProvider>(
      builder: (context, dashboardProvider, favoriteProvider, cartProvider, child) {
        final stats = dashboardProvider.dashboardStats;
        final isFavorite = favoriteProvider.isFavorite(_id);
        final isInCart = cartProvider.isInCart(_id);

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
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
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
                small: 6,
                medium: 8,
                large: 10,
              ),
            ),
            child: Stack(
              children: [
                Padding(
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
                                  small: 24,
                                  medium: 28,
                                  large: 32,
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

                      SizedBox(width: _mobileResponsiveValue(
                        context: context,
                        small: 12,
                        medium: 14,
                        large: 16,
                      )),

                      // Content Section - WITH RIGHT PADDING FOR HEART ICON
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: showFavoriteIcon
                                ? _mobileResponsiveValue(
                              context: context,
                              small: 24, // Space for heart icon
                              medium: 28,
                              large: 32,
                            )
                                : 0,
                          ),
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
                                        fontSize: _mobileResponsiveValue(
                                          context: context,
                                          small: 14,
                                          medium: 15,
                                          large: 16,
                                        ),
                                        fontWeight: FontWeight.w600,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: _mobileResponsiveValue(
                                context: context,
                                small: 4,
                                medium: 6,
                                large: 8,
                              )),

                              // Description
                              Text(
                                _description,
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: _mobileResponsiveValue(
                                    context: context,
                                    small: 11,
                                    medium: 12,
                                    large: 13,
                                  ),
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              SizedBox(height: _mobileResponsiveValue(
                                context: context,
                                small: 8,
                                medium: 10,
                                large: 12,
                              )),

                              // Subscribe/Progress Row - WITH FLEXIBLE FIX
                              Row(
                                children: [
                                  // Subscribe Text
                                  if (!_isSubscribed)
                                    Flexible(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: _mobileResponsiveValue(
                                            context: context,
                                            small: 8,
                                            medium: 10,
                                            large: 12,
                                          ),
                                          vertical: _mobileResponsiveValue(
                                            context: context,
                                            small: 3,
                                            medium: 4,
                                            large: 5,
                                          ),
                                        ),
                                        decoration: BoxDecoration(
                                          color: _blueWithOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _blueWithOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.lock_outline,
                                              size: _mobileResponsiveValue(
                                                context: context,
                                                small: 12,
                                                medium: 14,
                                                large: 16,
                                              ),
                                              color: progressColor,
                                            ),
                                            SizedBox(width: _mobileResponsiveValue(
                                              context: context,
                                              small: 4,
                                              medium: 6,
                                              large: 8,
                                            )),
                                            Flexible(
                                              child: Text(
                                                isSmallScreen ? 'Subscribe' : 'Subscribe to Access',
                                                style: TextStyle(
                                                  color: progressColor,
                                                  fontSize: _mobileResponsiveValue(
                                                    context: context,
                                                    small: 11,
                                                    medium: 12,
                                                    large: 13,
                                                  ),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  // Progress for subscribed users
                                  if (_isSubscribed)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Progress Bar
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: progressValue,
                                              backgroundColor: _whiteWithOpacity(0.1),
                                              color: progressColor,
                                              minHeight: _mobileResponsiveValue(
                                                context: context,
                                                small: 5,
                                                medium: 6,
                                                large: 7,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: _mobileResponsiveValue(
                                            context: context,
                                            small: 3,
                                            medium: 4,
                                            large: 5,
                                          )),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle_outline,
                                                size: _mobileResponsiveValue(
                                                  context: context,
                                                  small: 12,
                                                  medium: 14,
                                                  large: 16,
                                                ),
                                                color: progressColor,
                                              ),
                                              SizedBox(width: _mobileResponsiveValue(
                                                context: context,
                                                small: 4,
                                                medium: 6,
                                                large: 8,
                                              )),
                                              Flexible(
                                                child: Text(
                                                  '${progressPercent.round()}% complete',
                                                  style: TextStyle(
                                                    color: progressColor,
                                                    fontSize: _mobileResponsiveValue(
                                                      context: context,
                                                      small: 10,
                                                      medium: 11,
                                                      large: 12,
                                                    ),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Favorite Icon (TOP RIGHT CORNER of CARD)
                if (showFavoriteIcon)
                  Positioned(
                    top: 0, // TOP of card
                    right: 0, // RIGHT of card
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(borderRadius),
                          bottomLeft: Radius.circular(borderRadius),
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.white,
                          size: _mobileResponsiveValue(
                            context: context,
                            small: 18,
                            medium: 20,
                            large: 22,
                          ),
                        ),
                        onPressed: () {
                          favoriteProvider.toggleFavorite(_id);
                        },
                        padding: EdgeInsets.all(_mobileResponsiveValue(
                          context: context,
                          small: 6,
                          medium: 8,
                          large: 10,
                        )),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),

                // Cart Icon (BOTTOM RIGHT CORNER of CARD)
                if (showCartIcon && !_isSubscribed)
                  Positioned(
                    bottom: 0, // BOTTOM of card
                    right: 0, // RIGHT of card

                      child: IconButton(
                        icon: Icon(
                          isInCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                          color: isInCart ? Colors.green : Colors.white,
                          size: _mobileResponsiveValue(
                            context: context,
                            small: 18,
                            medium: 20,
                            large: 22,
                          ),
                        ),
                        onPressed: () {
                          if (isInCart) {
                            cartProvider.removeFromCart(_id);
                          } else {
                            cartProvider.addToCart(
                              courseId: _id,
                              title: _title,
                              price: _price,
                              thumbnailUrl: _thumbnailUrl,
                            );
                          }
                        },
                        padding: EdgeInsets.all(_mobileResponsiveValue(
                          context: context,
                          small: 6,
                          medium: 8,
                          large: 10,
                        )),
                        constraints: const BoxConstraints(),
                      ),
                    ),

              ],
            ),
          ),
        );
      },
    );
  }
}