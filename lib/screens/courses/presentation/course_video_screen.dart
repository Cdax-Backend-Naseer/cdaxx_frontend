import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart'; // Add this import

import '../../../providers/dashboard_provider.dart';
import '../../../widgets/app_video_player.dart';

class CourseVideoScreen extends StatefulWidget {
  const CourseVideoScreen({
    super.key,
    required this.videoUrl,
    this.videoId,
    this.courseId,
    this.moduleId,
    this.userId,
  });

  final String videoUrl;
  final String? videoId;
  final String? courseId;
  final String? moduleId;
  final String? userId;

  @override
  State<CourseVideoScreen> createState() => _CourseVideoScreenState();
}

class _CourseVideoScreenState extends State<CourseVideoScreen> {
  @override
  void initState() {
    super.initState();

    print('🎬 COURSE VIDEO SCREEN INITIALIZED:');
    print('   ├─ Constructor Parameters:');
    print('   │  ├─ videoUrl: ${widget.videoUrl}');
    print('   │  ├─ videoId: ${widget.videoId}');
    print('   │  ├─ courseId: ${widget.courseId}');
    print('   │  ├─ moduleId: ${widget.moduleId}');
    print('   │  └─ userId (from nav): ${widget.userId}');

    // Test YouTube URL conversion
    if (widget.videoUrl.isNotEmpty) {
      final youtubeId = YoutubePlayer.convertUrlToId(widget.videoUrl);
      print('   ├─ YouTube URL Analysis:');
      print('   │  ├─ URL: ${widget.videoUrl}');
      print('   │  └─ Extracted YouTube ID: $youtubeId');

      if (youtubeId == null) {
        print('   │  ❌ WARNING: Could not extract YouTube ID!');
      } else {
        print('   │  ✅ YouTube ID successfully extracted');
      }
    } else {
      print('   ├─ ❌ ERROR: videoUrl is empty!');
    }

    // Ensure portrait orientation when entering the screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    // Force portrait orientation when leaving the screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get userId from DashboardProvider
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    final providerUserId = dashboardProvider.currentUserId?.toString() ?? '0';

    // Decide which userId to use
    final String userId = widget.userId?.isNotEmpty == true ? widget.userId! : providerUserId;

    print('🎬 BUILDING COURSE VIDEO SCREEN:');
    print('   ├─ User ID Resolution:');
    print('   │  ├─ From navigation: ${widget.userId}');
    print('   │  ├─ From provider: $providerUserId');
    print('   │  └─ Final userId: $userId');

    // Validate all parameters
    final bool hasValidParams =
        widget.videoUrl.isNotEmpty &&
            widget.videoId != null &&
            widget.videoId!.isNotEmpty &&
            widget.courseId != null &&
            widget.courseId!.isNotEmpty &&
            widget.moduleId != null &&
            widget.moduleId!.isNotEmpty &&
            userId != '0' &&
            userId.isNotEmpty;

    print('   ├─ Parameter Validation:');
    print('   │  ├─ videoUrl isNotEmpty: ${widget.videoUrl.isNotEmpty}');
    print('   │  ├─ videoId is valid: ${widget.videoId != null && widget.videoId!.isNotEmpty}');
    print('   │  ├─ courseId is valid: ${widget.courseId != null && widget.courseId!.isNotEmpty}');
    print('   │  ├─ moduleId is valid: ${widget.moduleId != null && widget.moduleId!.isNotEmpty}');
    print('   │  ├─ userId is valid: ${userId != "0" && userId.isNotEmpty}');
    print('   │  └─ ALL VALID: $hasValidParams');

    // Show error if parameters are invalid
    if (!hasValidParams) {
      print('❌ FATAL: Missing required parameters! Showing error screen.');

      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Error - Cannot Play Video'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  'Cannot Play Video',
                  style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Missing required information:',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusRow('Video URL', widget.videoUrl.isNotEmpty),
                      _buildStatusRow('Video ID', widget.videoId != null && widget.videoId!.isNotEmpty),
                      _buildStatusRow('Course ID', widget.courseId != null && widget.courseId!.isNotEmpty),
                      _buildStatusRow('Module ID', widget.moduleId != null && widget.moduleId!.isNotEmpty),
                      _buildStatusRow('User ID', userId != "0" && userId.isNotEmpty),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Try to get fresh data from provider
                    print('🔄 Retrying with provider data...');
                    print('   Provider userId: $providerUserId');

                    if (providerUserId != '0') {
                      // Try again with provider userId
                      Navigator.of(context).pop();
                    } else {
                      print('❌ Provider also has no userId');
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    print('✅ All parameters valid, showing video player...');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Player'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Force portrait orientation before navigating back
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
            Navigator.of(context).pop();
          },
        ),
        actions: [
          // Debug button
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Video Debug Info'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Parameters:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Video URL: ${widget.videoUrl}'),
                        Text('Video ID: ${widget.videoId}'),
                        Text('Course ID: ${widget.courseId}'),
                        Text('Module ID: ${widget.moduleId}'),
                        Text('User ID (nav): ${widget.userId}'),
                        Text('User ID (final): $userId'),
                        const SizedBox(height: 16),
                        const Text('YouTube Analysis:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('YouTube ID: ${YoutubePlayer.convertUrlToId(widget.videoUrl)}'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.bug_report),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: AppVideoPlayer(
              videoUrl: widget.videoUrl,
              videoId: widget.videoId,
              courseId: widget.courseId,
              moduleId: widget.moduleId,
              userId: userId,
              onVideoCompleted: () {
                print('🎥 Video completed in CourseVideoScreen');
                // Optional: Navigate back or show completion message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Video completed!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.error,
            color: isValid ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            '$label: ${isValid ? "✓ OK" : "✗ MISSING"}',
            style: TextStyle(
              color: isValid ? Colors.green : Colors.red,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}