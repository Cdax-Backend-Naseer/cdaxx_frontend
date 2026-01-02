import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../services/backend_course_service.dart';
import 'course_list_card.dart';
import '../../../widgets/animations/staggered_list_animation.dart';

const LinearGradient _kDashboardBgGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF020617),
    Color(0xFF0F172A),
  ],
);

Color _whiteWithOpacity(double o) => Color.fromRGBO(255, 255, 255, o);
Color _blueWithOpacity(double o) => Color.fromRGBO(56, 189, 248, o);

enum SortBy {
  priceLowToHigh,
  priceHighToLow,
  rating,
  popularity,
  enrolledStudents,
  duration,
  newest,
}

class CourseFilterOptions {
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final bool? isPopular;
  final bool? isFeatured;
  final List<SortBy> sortByList;

  CourseFilterOptions({
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.isPopular,
    this.isFeatured,
    this.sortByList = const [],
  });

  bool get hasFilters =>
      minPrice != null ||
          maxPrice != null ||
          minRating != null ||
          isPopular != null ||
          isFeatured != null ||
          sortByList.isNotEmpty;

  CourseFilterOptions copyWith({
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? isPopular,
    bool? isFeatured,
    List<SortBy>? sortByList,
  }) {
    return CourseFilterOptions(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      isPopular: isPopular ?? this.isPopular,
      isFeatured: isFeatured ?? this.isFeatured,
      sortByList: sortByList ?? this.sortByList,
    );
  }

  CourseFilterOptions toggleSortBy(SortBy sortBy) {
    final newList = List<SortBy>.from(sortByList);
    if (newList.contains(sortBy)) {
      newList.remove(sortBy);
    } else {
      newList.add(sortBy);
    }
    return copyWith(sortByList: newList);
  }
}

class CourseListScreen extends StatefulWidget {
  final bool showSubscribedOnly;
  final Function(int)? onNavigateToTab;

  const CourseListScreen({
    super.key,
    this.showSubscribedOnly = false,
    this.onNavigateToTab,
  });

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final BackendCourseService _backendService = BackendCourseService();

  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';
  List<dynamic> _searchResults = [];

  CourseFilterOptions _filterOptions = CourseFilterOptions();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---------------- SEARCH ----------------

  void _onSearch(String q) {
    setState(() {
      _searchQuery = q.trim();
      _isSearching = _searchQuery.isNotEmpty;
    });

    if (_searchQuery.length >= 2) {
      _performSearch();
    } else {
      _searchResults.clear();
    }
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);

    final res = await _backendService.searchCourses(_searchQuery);
    if (res.isSuccess && res.data != null) {
      _searchResults = res.data!;
    }

    setState(() => _isLoading = false);
  }

  // ---------------- FILTER LOGIC ----------------

  List<dynamic> _applyFilters(List<dynamic> courses) {
    var list = List<dynamic>.from(courses);

    // Apply filter conditions
    list = list.where((c) {
      final price = c.price ?? c.discountPrice ?? 0.0;
      final rating = c.rating ?? 0.0;

      if (_filterOptions.minPrice != null && price < _filterOptions.minPrice!) return false;
      if (_filterOptions.maxPrice != null && price > _filterOptions.maxPrice!) return false;
      if (_filterOptions.minRating != null && rating < _filterOptions.minRating!) return false;
      if (_filterOptions.isPopular != null && c.isPopular != _filterOptions.isPopular) return false;
      if (_filterOptions.isFeatured != null && c.isFeatured != _filterOptions.isFeatured) return false;

      return true;
    }).toList();

    // Apply user-selected sorting (filters override any default sorting)
    if (_filterOptions.sortByList.isNotEmpty) {
      list.sort((a, b) {
        for (final sortBy in _filterOptions.sortByList) {
          int result = 0;
          switch (sortBy) {
            case SortBy.priceLowToHigh:
              result = (a.price ?? 0).compareTo(b.price ?? 0);
              break;
            case SortBy.priceHighToLow:
              result = (b.price ?? 0).compareTo(a.price ?? 0);
              break;
            case SortBy.rating:
              result = (b.rating ?? 0).compareTo(a.rating ?? 0);
              break;
            case SortBy.popularity:
              result = (b.isPopular == true ? 1 : 0).compareTo(a.isPopular == true ? 1 : 0);
              break;
            case SortBy.enrolledStudents:
              result = (b.enrolledStudents ?? 0).compareTo(a.enrolledStudents ?? 0);
              break;
            case SortBy.duration:
              result = (a.totalDuration ?? 0).compareTo(b.totalDuration ?? 0);
              break;
            case SortBy.newest:
              final dateA = a.createdAt is String ? DateTime.parse(a.createdAt) : (a.createdAt ?? DateTime.now());
              final dateB = b.createdAt is String ? DateTime.parse(b.createdAt) : (b.createdAt ?? DateTime.now());
              result = dateB.compareTo(dateA);
              break;
          }
          if (result != 0) return result;
        }
        return 0;
      });
    }
    // When no filters are applied, the default sorting (if any) from the dashboard provider is used

    return list;
  }

  // ---------------- FILTER DIALOG ----------------

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(builder: (c, setModal) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: _kDashboardBgGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter & Sort',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 24),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Sort options - Multi-select chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SortBy.values.map((s) {
                    final selected = _filterOptions.sortByList.contains(s);
                    return FilterChip(
                      selected: selected,
                      selectedColor: const Color(0xFF38BDF8),
                      backgroundColor: Colors.transparent,
                      side: BorderSide(
                        color: selected ? const Color(0xFF38BDF8) : Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                      label: Text(
                        _getSortByLabel(s),
                        style: TextStyle(
                          color: selected ? Colors.black : Colors.black,
                          fontSize: 14,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      onSelected: (v) {
                        setModal(() {
                          _filterOptions = _filterOptions.toggleSortBy(s);
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      showCheckmark: false,
                    );
                  }).toList(),
                ),

                // Multi-selection tip
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Tip: Select multiple filters to apply in order',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // REMOVE ALL button at top
                if (_filterOptions.hasFilters)
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            setModal(() {
                              _filterOptions = CourseFilterOptions();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF38BDF8),
                            side: const BorderSide(color: Color(0xFF38BDF8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_outline, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Remove All Filters',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        });
      },
    );
  }

  // Helper function for sort labels
  String _getSortByLabel(SortBy sortBy) {
    switch (sortBy) {
      case SortBy.priceLowToHigh:
        return 'Price: Low to High';
      case SortBy.priceHighToLow:
        return 'Price: High to Low';
      case SortBy.rating:
        return 'Highest Rated';
      case SortBy.popularity:
        return 'Most Popular';
      case SortBy.enrolledStudents:
        return 'Most Enrolled';
      case SortBy.duration:
        return 'Shortest Duration';
      case SortBy.newest:
        return 'Newest First';
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();

    final baseCourses = widget.showSubscribedOnly
        ? dashboard.enrolledCourses
        : dashboard.userCourses ?? [];

    /// 🔥 STRICT MODE LOGIC
    List<dynamic> coursesToShow;

    if (_isSearching) {
      coursesToShow = _searchResults;
    } else if (_filterOptions.hasFilters) {
      coursesToShow = _applyFilters(baseCourses);
    } else {
      coursesToShow = baseCourses;
    }

    return Container(
      decoration: const BoxDecoration(gradient: _kDashboardBgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.showSubscribedOnly ? 'My Courses' : 'All Courses',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              if (widget.onNavigateToTab != null) {
                widget.onNavigateToTab!(0);
              }
            },
          ),
          actions: [
            // Filter button with badge
            Stack(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.filter_alt,
                    color: _filterOptions.hasFilters
                        ? const Color(0xFF38BDF8)
                        : Colors.white70,
                    size: 24,
                  ),
                  onPressed: () => _showFilterDialog(context),
                ),
                if (_filterOptions.hasFilters)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF38BDF8),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_filterOptions.sortByList.length}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search courses...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearch('');
                      },
                    )
                        : null,
                  ),
                ),
              ),
            ),

            // Results count and active filters display
            if (!_isLoading && coursesToShow.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Results count
                    Text(
                      '${coursesToShow.length} course${coursesToShow.length == 1 ? '' : 's'} found',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),

                    // Active sort filters
                    if (_filterOptions.sortByList.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ..._filterOptions.sortByList.map((sortBy) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF38BDF8).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _getSortByLabel(sortBy),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _filterOptions = _filterOptions.toggleSortBy(sortBy);
                                        });
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Color(0xFF38BDF8),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),

                    // Clear all button
                    if (_filterOptions.hasFilters)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _filterOptions = CourseFilterOptions();
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close, size: 16, color: Color(0xFF38BDF8)),
                              SizedBox(width: 4),
                              Text(
                                'Remove all filters',
                                style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Loading or results
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF38BDF8),
                ),
              )
                  : coursesToShow.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isSearching
                          ? Icons.search_off
                          : Icons.menu_book,
                      color: Colors.white70,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isSearching
                          ? 'No courses found for "$_searchQuery"'
                          : 'No courses found',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_filterOptions.hasFilters)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _filterOptions = CourseFilterOptions();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF38BDF8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Remove All Filters'),
                        ),
                      ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: coursesToShow.length,
                itemBuilder: (c, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: StaggeredListAnimation(
                    index: i,
                    child: CourseListCard(course: coursesToShow[i]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}