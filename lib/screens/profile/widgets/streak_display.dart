import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/http_service.dart';
import '/providers/user_provider.dart';

class StreakDisplay extends StatefulWidget {
  const StreakDisplay({super.key});

  @override
  State<StreakDisplay> createState() => _StreakDisplayState();
}

class _StreakDisplayState extends State<StreakDisplay> {
  Map<String, dynamic>? _streakData;
  List<Map<String, String>> _courses = [];
  bool _loading = true;
  bool _loadingStreak = false;
  String? _selectedCourseId;
  String? _selectedCourseTitle;
  String? _errorMessage;

  final HttpService _httpService = HttpService();
  DateTime _currentMonth = DateTime.now();
  final Map<DateTime, Map<String, dynamic>> _monthCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCourses();
    });
  }

  double _getDisplayProgress(double actualProgress) {
    return actualProgress >= 95 ? 100 : actualProgress;
  }

  String _getProgressText(double actualProgress) {
    final displayProgress = _getDisplayProgress(actualProgress);
    return displayProgress.toStringAsFixed(displayProgress >= 100 ? 0 : 1);
  }

  Future<void> _loadCourses() async {
    try {
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.currentUser?.id?.toString();

      if (userId == null) {
        setState(() {
          _loading = false;
          _errorMessage = 'User not logged in';
        });
        return;
      }

      final response = await _httpService.get<List<dynamic>>(
        '/courses/subscribed/$userId',
            (data) => data as List<dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final coursesList = response.data!
            .map<Map<String, String>>((course) => {
          'id': course['id']?.toString() ?? '',
          'title': course['title']?.toString() ?? 'Unknown Course',
        })
            .where((c) => c['id']!.isNotEmpty)
            .toList();

        setState(() {
          _courses = coursesList;
          _loading = false;
          _errorMessage = null;
        });

        if (_courses.isNotEmpty) {
          setState(() {
            _selectedCourseId = _courses.first['id'];
            _selectedCourseTitle = _courses.first['title'];
          });
          _loadStreakDataForMonth();
        }
      } else {
        setState(() {
          _loading = false;
          _errorMessage = 'Failed to load courses';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Error loading courses';
      });
    }
  }

  Future<void> _loadStreakDataForMonth() async {
    if (_selectedCourseId == null) return;

    final cacheKey = DateTime(_currentMonth.year, _currentMonth.month);
    if (_monthCache.containsKey(cacheKey)) {
      setState(() {
        _streakData = _monthCache[cacheKey];
        _loadingStreak = false;
      });
      return;
    }

    setState(() => _loadingStreak = true);

    try {
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.currentUser?.id?.toString();

      if (userId == null) {
        setState(() {
          _streakData = null;
          _loadingStreak = false;
          _errorMessage = 'User not logged in';
        });
        return;
      }

      final response = await _httpService.get<Map<String, dynamic>>(
        '/streak/course/$_selectedCourseId?userId=$userId',
            (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        final last30Days = data['last30Days'] as List<dynamic>? ?? [];

        final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
        final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

        final monthDays = _filterAndFillMonthDays(last30Days, firstDay, lastDay);

        final updatedData = Map<String, dynamic>.from(data)
          ..['monthDays'] = monthDays
          ..['courseTitle'] = data['courseTitle'] ?? ''
          ..['currentStreakDays'] = data['currentStreakDays'] ?? 0
          ..['overallProgress'] = data['overallProgress'] ?? 0.0;

        _monthCache[cacheKey] = updatedData;

        setState(() {
          _streakData = updatedData;
          _loadingStreak = false;
          _errorMessage = null;
        });
      } else {
        _setEmptyMonthData(cacheKey);
      }
    } catch (e) {
      _setEmptyMonthData(DateTime(_currentMonth.year, _currentMonth.month));
    }
  }

  List<Map<String, dynamic>> _filterAndFillMonthDays(
      List<dynamic> last30Days,
      DateTime firstDay,
      DateTime lastDay,
      ) {
    final Map<String, Map<String, dynamic>> existingDays = {};

    for (var day in last30Days) {
      final dateStr = day['date'];
      if (dateStr is String) {
        try {
          final date = DateTime.parse(dateStr);
          if (date.isAfter(firstDay.subtract(const Duration(days: 1))) &&
              date.isBefore(lastDay.add(const Duration(days: 1)))) {
            existingDays[dateStr] = Map<String, dynamic>.from(day);
          }
        } catch (_) {}
      }
    }

    final List<Map<String, dynamic>> filledDays = [];
    DateTime currentDate = firstDay;

    while (currentDate.isBefore(lastDay.add(const Duration(days: 1)))) {
      final dateStr =
          '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';

      filledDays.add(existingDays[dateStr] ?? _createEmptyDay(dateStr));
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return filledDays;
  }

  Map<String, dynamic> _createEmptyDay(String date) {
    return {
      'date': date,
      'isActiveDay': false,
      'progressPercentage': 0.0,
      'watchedSeconds': 0,
      'videoDetails': [],
    };
  }

  void _setEmptyMonthData(DateTime cacheKey) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final monthDays = <Map<String, dynamic>>[];

    DateTime currentDate = firstDay;
    while (currentDate.isBefore(lastDay.add(const Duration(days: 1)))) {
      monthDays.add(_createEmptyDay(
        '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}',
      ));
      currentDate = currentDate.add(const Duration(days: 1));
    }

    final emptyData = {
      'courseTitle': _selectedCourseTitle ?? 'Selected Course',
      'currentStreakDays': 0,
      'overallProgress': 0.0,
      'monthDays': monthDays,
    };

    _monthCache[cacheKey] = emptyData;

    setState(() {
      _streakData = emptyData;
      _loadingStreak = false;
      _errorMessage = 'No streak data available';
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _streakData = null;
    });
    _loadStreakDataForMonth();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _streakData = null;
    });
    _loadStreakDataForMonth();
  }

  Color _getDayColor(bool isActive, double progress) {
    if (!isActive) return Colors.white.withOpacity(0.08);
    if (progress < 25) return const Color(0xFFFEF3C7);
    if (progress < 50) return const Color(0xFFFDE68A);
    if (progress < 75) return const Color(0xFFFBBF24);
    if (progress < 100) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          if (_errorMessage != null) _buildError(),
          if (_loading) _buildLoading(),
          if (!_loading && _courses.isEmpty) _buildNoCourses(),
          if (!_loading && _courses.isNotEmpty) _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.local_fire_department,
            color: Color(0xFFF59E0B), size: 20),
        const SizedBox(width: 8),
        Text(
          'Learning Streak',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.error, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Error',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadCourses,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 36),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(color: Color(0xFF38BDF8)),
            SizedBox(height: 12),
            Text('Loading streak data...',
                style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCourses() {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.school, color: Colors.white70, size: 40),
            SizedBox(height: 12),
            Text(
              'No enrolled courses',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 4),
            Text(
              'Enroll in courses to track your streak',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCourseSelector(),
        const SizedBox(height: 16),
        if (_loadingStreak)
          SizedBox(
            height: 100,
            child: Center(
                child: CircularProgressIndicator(color: Color(0xFF38BDF8))),
          )
        else if (_streakData != null && _streakData!.isNotEmpty)
          _buildStreakContent()
        else
          _buildEmptyStreak(),
      ],
    );
  }

  Widget _buildCourseSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedCourseId,
      decoration: InputDecoration(
        labelText: 'Select Course',
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF38BDF8)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: const Color(0xFF0F172A),
      ),
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      items: _courses
          .map((course) => DropdownMenuItem<String>(
        value: course['id'],
        child: Text(
          course['title']!,
          style: const TextStyle(color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedCourseId = value;
          final selectedCourse = _courses.firstWhere(
                (c) => c['id'] == value,
            orElse: () => {'id': value ?? '', 'title': 'Selected Course'},
          );
          _selectedCourseTitle = selectedCourse['title'];
          _streakData = null;
          _monthCache.clear();
        });
        _loadStreakDataForMonth();
      },
    );
  }

  Widget _buildStreakContent() {
    final courseTitle =
        _streakData!['courseTitle'] ?? _selectedCourseTitle ?? 'Course';
    final currentStreak = _streakData!['currentStreakDays'] ?? 0;
    final overallProgress = _streakData!['overallProgress'] ?? 0.0;
    final monthDays = _streakData!['monthDays'] as List<dynamic>? ?? [];

    final activeDays = monthDays
        .where((day) => (day['isActiveDay'] ?? false) == true)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMonthNavigation(),
        const SizedBox(height: 12),
        _buildStreakSummary(courseTitle, currentStreak, activeDays, monthDays,
            overallProgress),
        const SizedBox(height: 12),
        _buildWeekHeaders(),
        const SizedBox(height: 8),
        _buildMonthGrid(monthDays),
        const SizedBox(height: 8),
        _buildViewDetailsButton(),
      ],
    );
  }

  Widget _buildMonthNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _previousMonth,
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          iconSize: 24,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Expanded(
          child: Center(
            child: Text(
              '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: _nextMonth,
          icon: const Icon(Icons.chevron_right, color: Colors.white),
          iconSize: 24,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildStreakSummary(String courseTitle, int currentStreak,
      int activeDays, List<dynamic> monthDays, double overallProgress) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                courseTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '$currentStreak day streak • $activeDays/${monthDays.length} active days',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_getProgressText(overallProgress)}%',
            style: const TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekHeaders() {
    return Row(
      children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
          .map((day) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ),
      ))
          .toList(),
    );
  }

  Widget _buildMonthGrid(List<dynamic> monthDays) {
    if (monthDays.isEmpty) return const SizedBox();

    final firstDay = DateTime.parse(monthDays.first['date']);
    final firstWeekday = firstDay.weekday % 7;
    final totalDays = monthDays.length;
    final totalCells = ((totalDays + firstWeekday + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1.0,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < firstWeekday || index >= firstWeekday + totalDays) {
          return Container();
        }

        final dayIndex = index - firstWeekday;
        final day = monthDays[dayIndex];
        final isActive = day['isActiveDay'] ?? false;
        final progress = day['progressPercentage'] ?? 0.0;

        return InkWell(
          onTap: () => _showDayDetails(context, day),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            decoration: BoxDecoration(
              color: _getDayColor(isActive, progress),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                DateTime.parse(day['date']).day.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? Colors.black87 : Colors.white54,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewDetailsButton() {
    return Center(
      child: TextButton(
        onPressed: () => _showStreakDetails(context),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF38BDF8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility, size: 16),
            SizedBox(width: 4),
            Text('View Details'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStreak() {
    return SizedBox(
      height: 100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.local_fire_department, color: Colors.white70, size: 32),
            SizedBox(height: 8),
            Text(
              'No streak data yet',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 4),
            Text(
              'Watch videos to start your streak',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showDayDetails(BuildContext context, Map<String, dynamic> dayData) {
    final date = DateTime.parse(dayData['date']);
    final isActive = dayData['isActiveDay'] ?? false;
    final progress = dayData['progressPercentage'] ?? 0.0;
    final watchedSeconds = dayData['watchedSeconds'] ?? 0;
    final videoDetails = dayData['videoDetails'] ?? [];

    showDialog(
      context: context,
      builder: (_) => _DayDetailsDialog(
        date: date,
        isActive: isActive,
        progress: progress,
        watchedSeconds: watchedSeconds,
        videoDetails: videoDetails,
        getProgressText: _getProgressText,
        getDisplayProgress: _getDisplayProgress,
      ),
    );
  }

  void _showStreakDetails(BuildContext context) {
    if (_streakData == null) return;

    showDialog(
      context: context,
      builder: (_) => _StreakDetailsDialog(
        courseTitle: _streakData!['courseTitle'] ?? _selectedCourseTitle,
        monthDays: _streakData!['monthDays'] as List<dynamic>? ?? [],
        currentMonth: _currentMonth,
        showDayDetails: (day) => _showDayDetails(context, day),
        getProgressText: _getProgressText,
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }
    return '${duration.inMinutes}m';
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}

class _DayDetailsDialog extends StatelessWidget {
  final DateTime date;
  final bool isActive;
  final double progress;
  final int watchedSeconds;
  final List<dynamic> videoDetails;
  final String Function(double) getProgressText;
  final double Function(double) getDisplayProgress;

  const _DayDetailsDialog({
    required this.date,
    required this.isActive,
    required this.progress,
    required this.watchedSeconds,
    required this.videoDetails,
    required this.getProgressText,
    required this.getDisplayProgress,
  });

  Color _getDayColor() {
    if (!isActive) return Colors.white.withOpacity(0.08);
    if (progress < 25) return const Color(0xFFFEF3C7);
    if (progress < 50) return const Color(0xFFFDE68A);
    if (progress < 75) return const Color(0xFFFBBF24);
    if (progress < 100) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String _getColorExplanation() {
    if (!isActive) return 'Gray: No activity on this day';
    if (progress < 25) return 'Light Yellow: 1-25% daily progress';
    if (progress < 50) return 'Yellow: 25-50% daily progress';
    if (progress < 75) return 'Orange: 50-75% daily progress';
    if (progress < 100) return 'Dark Orange: 75-99% daily progress';
    return 'Green: 100% daily goal achieved! 🎉';
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }
    return '${duration.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getDayColor(),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                date.day.toString(),
                style: TextStyle(
                  fontSize: 16,
                  color: isActive ? Colors.black87 : Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${months[date.month - 1]} ${date.day}, ${date.year}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  isActive ? 'Active Day' : 'No Activity',
                  style: TextStyle(
                    color: isActive ? const Color(0xFF10B981) : Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: _DayDetailsContent(
            progress: progress,
            watchedSeconds: watchedSeconds,
            videoDetails: videoDetails,
            isActive: isActive,
            getProgressText: getProgressText,
            getDisplayProgress: getDisplayProgress,
            getDayColor: _getDayColor(),
            colorExplanation: _getColorExplanation(),
            formatDuration: _formatDuration,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _DayDetailsContent extends StatelessWidget {
  final double progress;
  final int watchedSeconds;
  final List<dynamic> videoDetails;
  final bool isActive;
  final String Function(double) getProgressText;
  final double Function(double) getDisplayProgress;
  final Color getDayColor;
  final String colorExplanation;
  final String Function(int) formatDuration;

  const _DayDetailsContent({
    required this.progress,
    required this.watchedSeconds,
    required this.videoDetails,
    required this.isActive,
    required this.getProgressText,
    required this.getDisplayProgress,
    required this.getDayColor,
    required this.colorExplanation,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildProgressSummary(),
        const SizedBox(height: 16),
        if (videoDetails.isNotEmpty) _buildVideosWatched(),
        if (videoDetails.isEmpty && isActive) _buildNoVideoDetails(),
        if (!isActive) _buildNoActivity(),
        const SizedBox(height: 16),
        _buildColorExplanation(),
      ],
    );
  }

  Widget _buildProgressSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${getProgressText(progress)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Watch Time',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDuration(watchedSeconds),
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: getDisplayProgress(progress) / 100,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(getDayColor),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildVideosWatched() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Videos Watched (${videoDetails.length})',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...videoDetails.map((video) {
          final videoTitle = video['videoTitle'] ?? 'Unknown Video';
          final videoProgress = video['videoProgress'] ?? 0.0;
          final videoWatchedSeconds = video['watchedSeconds'] ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.play_circle_outline,
                        color: Color(0xFF38BDF8), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        videoTitle,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${getProgressText(videoProgress)}% completed',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    Text(
                      formatDuration(videoWatchedSeconds),
                      style:
                      const TextStyle(color: Color(0xFF38BDF8), fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: getDisplayProgress(videoProgress) / 100,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildNoVideoDetails() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No video details available',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildNoActivity() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.event_busy, color: Colors.white54, size: 40),
            SizedBox(height: 8),
            Text(
              'No activity on this day',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorExplanation() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: getDayColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: getDayColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              colorExplanation,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakDetailsDialog extends StatelessWidget {
  final String? courseTitle;
  final List<dynamic> monthDays;
  final DateTime currentMonth;
  final Function(Map<String, dynamic>) showDayDetails;
  final String Function(double) getProgressText;

  const _StreakDetailsDialog({
    required this.courseTitle,
    required this.monthDays,
    required this.currentMonth,
    required this.showDayDetails,
    required this.getProgressText,
  });

  Color _getDayColor(bool isActive, double progress) {
    if (!isActive) return Colors.white.withOpacity(0.08);
    if (progress < 25) return const Color(0xFFFEF3C7);
    if (progress < 50) return const Color(0xFFFDE68A);
    if (progress < 75) return const Color(0xFFFBBF24);
    if (progress < 100) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(courseTitle ?? 'Course',
              style: const TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            '${_getMonthName(currentMonth.month)} ${currentMonth.year} - Activity',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildWeekHeaders(),
              const SizedBox(height: 8),
              _buildDetailedMonthGrid(),
              const SizedBox(height: 16),
              _buildLegend(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildWeekHeaders() {
    return Row(
      children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
          .map((day) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ),
      ))
          .toList(),
    );
  }

  Widget _buildDetailedMonthGrid() {
    if (monthDays.isEmpty) return const SizedBox();

    final firstDay = DateTime.parse(monthDays.first['date']);
    final firstWeekday = firstDay.weekday % 7;
    final totalDays = monthDays.length;
    final totalCells = ((totalDays + firstWeekday + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < firstWeekday || index >= firstWeekday + totalDays) {
          return Container();
        }

        final dayIndex = index - firstWeekday;
        final day = monthDays[dayIndex];
        final isActive = day['isActiveDay'] ?? false;
        final progress = day['progressPercentage'] ?? 0.0;

        return InkWell(
          onTap: () => showDayDetails(day),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            decoration: BoxDecoration(
              color: _getDayColor(isActive, progress),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateTime.parse(day['date']).day.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? Colors.black87 : Colors.white54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isActive)
                    Text(
                      '${getProgressText(progress)}%',
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.black87,
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

  Widget _buildLegend() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildLegendItem('0%', Colors.white.withOpacity(0.08)),
        _buildLegendItem('1-25%', const Color(0xFFFEF3C7)),
        _buildLegendItem('25-50%', const Color(0xFFFDE68A)),
        _buildLegendItem('50-75%', const Color(0xFFFBBF24)),
        _buildLegendItem('75-99%', const Color(0xFFF59E0B)),
        _buildLegendItem('100%', const Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}