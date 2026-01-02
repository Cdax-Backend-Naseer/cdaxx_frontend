import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:async';
import '/config/environment_config.dart';

class AppVideoPlayer extends StatefulWidget {

  const AppVideoPlayer({
    super.key,
    required this.videoUrl,
    this.videoId,
    this.courseId,
    this.moduleId,
    this.userId,
    this.videoDuration, // Add video duration parameter
    this.onVideoCompleted,
  });

  final String videoUrl;
  final String? videoId;
  final String? courseId;
  final String? moduleId;
  final String? userId;
  final Duration? videoDuration; // Expected video duration
  final VoidCallback? onVideoCompleted;

  @override
  State<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  final String baseUrl = EnvironmentConfig.baseUrl;
  VideoPlayerController? _videoCtrl;
  ChewieController? _chewieCtrl;
  YoutubePlayerController? _youtubeCtrl;
  bool _initError = false;
  bool _isYouTubeUrl = false;
  bool _isInitialized = false;
  String? _youtubeId;
  bool _videoMarkedAsCompleted = false;

  // Timer tracking variables
  Timer? _watchTimer;
  int _forwardButtonCount = 0; // Counts +10 forward button presses
  Duration _totalWatchedTime = Duration.zero;
  Duration _lastPosition = Duration.zero;
  bool _isDragging = false;
  Duration? _actualVideoDuration; // Actual duration from video player
  DateTime? _videoStartTime;
  List<Duration> _forwardJumps = []; // Track forward jump timestamps

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(AppVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _resetTracking();
      _dispose();
      _initialize();
    }
  }

  void _resetTracking() {
    _watchTimer?.cancel();
    _videoMarkedAsCompleted = false;
    _forwardButtonCount = 0;
    _totalWatchedTime = Duration.zero;
    _lastPosition = Duration.zero;
    _isDragging = false;
    _forwardJumps.clear();
    _videoStartTime = null;
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      final String? youtubeId = YoutubePlayer.convertUrlToId(widget.videoUrl);

      debugPrint('🎥 Video URL: ${widget.videoUrl}');
      debugPrint('🔍 Extracted YouTube ID: $youtubeId');
      debugPrint('🎯 Video ID: ${widget.videoId}');
      debugPrint('👤 User ID: ${widget.userId}');
      debugPrint('⏱️ Expected Duration: ${widget.videoDuration}');

      if (youtubeId != null) {
        // YouTube URL
        if (!kIsWeb) {
          final youtubeController = YoutubePlayerController(
            initialVideoId: youtubeId,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
              enableCaption: true,
              loop: false,
              showLiveFullscreenButton: true,
              forceHD: false,
              useHybridComposition: true,
            ),
          );

          youtubeController.addListener(() {
            _handleYouTubeVideoState(youtubeController);
          });

          if (!mounted) return;
          setState(() {
            _youtubeCtrl = youtubeController;
            _youtubeId = youtubeId;
            _isYouTubeUrl = true;
            _isInitialized = true;
          });
        } else {
          if (!mounted) return;
          setState(() {
            _youtubeId = youtubeId;
            _isYouTubeUrl = true;
            _isInitialized = true;
          });
        }
      } else {
        // Regular video URL
        final video = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
        await video.initialize();

        // Store actual duration
        _actualVideoDuration = video.value.duration;

        final chewie = ChewieController(
          videoPlayerController: video,
          autoPlay: false,
          looping: false,
          allowMuting: true,
          allowFullScreen: true,
          showControls: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: Colors.redAccent,
            bufferedColor: Colors.white70,
            handleColor: Colors.white,
            backgroundColor: Colors.black26,
          ),
        );

        video.addListener(() {
          _handleRegularVideoState(video);
        });

        if (!mounted) return;
        setState(() {
          _videoCtrl = video;
          _chewieCtrl = chewie;
          _isYouTubeUrl = false;
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Video initialization error: $e');
      if (!mounted) return;
      setState(() {
        _initError = true;
        _isInitialized = true;
      });
    }
  }

  void _handleYouTubeVideoState(YoutubePlayerController controller) {
    if (!controller.value.isReady) return;

    final currentPosition = controller.value.position;
    final playerState = controller.value.playerState;

    // Track play/pause
    if (playerState == PlayerState.playing) {
      if (_videoStartTime == null) {
        _videoStartTime = DateTime.now();
        _startWatchTimer();
      }
    } else if (playerState == PlayerState.paused) {
      _watchTimer?.cancel();
    }

    // Track forward jumps
    if (_lastPosition.inSeconds > 0) {
      final jump = currentPosition - _lastPosition;
      if (jump.inSeconds >= 10) {
        // Detected a forward jump of 10+ seconds
        _forwardButtonCount++;
        _forwardJumps.add(currentPosition);
        debugPrint('⏩ Forward jump detected: $jump (count: $_forwardButtonCount)');
      }
    }

    _lastPosition = currentPosition;

    // Check for completion
    if (playerState == PlayerState.ended && !_videoMarkedAsCompleted) {
      _evaluateCompletion();
    }
  }

  void _handleRegularVideoState(VideoPlayerController controller) {
    if (!controller.value.isInitialized) return;

    final currentPosition = controller.value.position;
    final isPlaying = controller.value.isPlaying;

    // Track play/pause
    if (isPlaying) {
      if (_videoStartTime == null) {
        _videoStartTime = DateTime.now();
        _startWatchTimer();
      }
    } else {
      _watchTimer?.cancel();
    }

    // Track forward jumps (from dragging or forward button)
    if (!_isDragging && _lastPosition.inSeconds > 0) {
      final jump = currentPosition - _lastPosition;
      if (jump.inSeconds >= 10) {
        // Detected a forward jump of 10+ seconds
        _forwardButtonCount++;
        _forwardJumps.add(currentPosition);
        debugPrint('⏩ Forward jump detected: $jump (count: $_forwardButtonCount)');
      }
    }

    _lastPosition = currentPosition;

    // Check if user dragged to end without watching
    final isNearEnd = currentPosition >= controller.value.duration * 0.95;
    if (isNearEnd && !_videoMarkedAsCompleted) {
      _evaluateCompletion();
    }
  }

// Update your timer to call this periodically
  void _startWatchTimer() {
    _watchTimer?.cancel();
    _watchTimer = Timer.periodic(const Duration(seconds: 30), (timer) async { // Every 30 seconds
      if (_videoStartTime != null) {
        _totalWatchedTime = _totalWatchedTime + const Duration(seconds: 30);
        debugPrint('⏱️ Total watched time: $_totalWatchedTime');

        // Send progress update to backend
        await _sendProgressUpdate();

        // Check if we've watched enough
        final targetDuration = _actualVideoDuration ?? widget.videoDuration;
        if (targetDuration != null) {
          final requiredWatchTime = targetDuration * 0.95;
          if (_totalWatchedTime >= requiredWatchTime) {
            debugPrint('✅ Watched 95% of video duration');
            _evaluateCompletion();
          }
        }
      }
    });
  }

  void _handleDragStart() {
    _isDragging = true;
    _watchTimer?.cancel();
  }

  void _handleDragEnd() {
    _isDragging = false;
    if ((_videoCtrl?.value.isPlaying ?? false) ||
        (_youtubeCtrl?.value.playerState == PlayerState.playing)) {
      _startWatchTimer();
    }
  }

  Future<void> _evaluateCompletion() async {
    if (_videoMarkedAsCompleted) return;

    final targetDuration = _actualVideoDuration ?? widget.videoDuration;
    if (targetDuration == null) {
      debugPrint('⚠️ Cannot evaluate: Video duration unknown');
      return;
    }

    final requiredWatchTime = targetDuration * 0.95;
    final skippedTooMuch = _forwardButtonCount >= 10;

    debugPrint('\n📊 Completion Evaluation:');
    debugPrint('  Total watched: $_totalWatchedTime');
    debugPrint('  Required (95%): $requiredWatchTime');
    debugPrint('  Forward button presses: $_forwardButtonCount');
    debugPrint('  Skipped too much: $skippedTooMuch');

    // Check completion criteria
    if (_totalWatchedTime >= requiredWatchTime && !skippedTooMuch) {
      await _markVideoAsCompleted();
    } else {
      debugPrint('❌ Video NOT marked as complete:');
      if (_totalWatchedTime < requiredWatchTime) {
        debugPrint('  - Watched only ${(_totalWatchedTime.inSeconds / targetDuration.inSeconds * 100).toStringAsFixed(1)}% of video');
      }
      if (skippedTooMuch) {
        debugPrint('  - Skipped too much (forwarded $_forwardButtonCount times)');
      }

      // Show feedback to user
      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              skippedTooMuch
                  ? 'Watch more of the video to complete it'
                  : 'Please watch more of the video to mark it complete',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

// In your Flutter AppVideoPlayer widget, update the _markVideoAsCompleted method:

  Future<void> _sendProgressUpdate() async {
    if (widget.videoId == null || widget.userId == null) return;

    try {
      final videoId = int.tryParse(widget.videoId!);
      final userId = int.tryParse(widget.userId!);

      if (videoId == null || userId == null) return;

      final url = '$baseUrl/api/videos/$videoId/progress';

      final progressData = {
        'videoId': videoId,
        'userId': userId,
        'watchedSeconds': _totalWatchedTime.inSeconds,
        'lastPositionSeconds': _lastPosition.inSeconds,
        'forwardJumpsCount': _forwardButtonCount,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(progressData),
      );

      if (response.statusCode == 200) {
        debugPrint('📊 Progress updated: ${_totalWatchedTime.inSeconds}s watched');
      }
    } catch (e) {
      debugPrint('❌ Error updating progress: $e');
    }
  }

  Future<void> _markVideoAsCompleted() async {
    if (_videoMarkedAsCompleted) return;

    // Check if we have all required IDs
    if (widget.videoId == null ||
        widget.userId == null ||
        widget.courseId == null ||
        widget.moduleId == null) {
      debugPrint('⚠️ Missing IDs for video completion');
      return;
    }

    try {
      debugPrint('📞 Calling video completion API...');

      // Parse IDs
      final videoId = int.tryParse(widget.videoId!);
      final userId = int.tryParse(widget.userId!);
      final courseId = int.tryParse(widget.courseId!);
      final moduleId = int.tryParse(widget.moduleId!);

      if (videoId == null || userId == null) {
        debugPrint('❌ Failed to parse required IDs');
        return;
      }

      // FIXED: Create proper URL with only videoId in path
      final url = '$baseUrl/api/videos/$videoId/complete';
      debugPrint('   ├─ API URL: $url');

      // FIXED: Create query parameters
      final uri = Uri.parse(url).replace(queryParameters: {
        'userId': userId.toString(),
        if (courseId != null) 'courseId': courseId.toString(),
        if (moduleId != null) 'moduleId': moduleId.toString(),
      });

      debugPrint('   ├─ Full URI: $uri');

      // Make POST request with empty body (parameters are in URL)
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('   ├─ Response Status: ${response.statusCode}');
      debugPrint('   ├─ Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          debugPrint('✅ Video $videoId marked as completed in database!');
          _videoMarkedAsCompleted = true;
          _watchTimer?.cancel();

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video completed! Progress saved.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }

          // Call parent callback
          widget.onVideoCompleted?.call();
        } else {
          debugPrint('❌ API returned error: ${responseData['error']}');
        }
      } else {
        debugPrint('❌ Failed to mark video complete: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');

        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save progress: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error marking video complete: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _testMarkAsCompleted() {
    debugPrint('🧪 Manual test: Marking video as completed');
    _markVideoAsCompleted();
  }

  void _showWatchStats() {
    final targetDuration = _actualVideoDuration ?? widget.videoDuration;
    final percentage = targetDuration != null
        ? (_totalWatchedTime.inSeconds / targetDuration.inSeconds * 100).toStringAsFixed(1)
        : 'N/A';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Watch Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total watched: $_totalWatchedTime'),
            Text('Forward button presses: $_forwardButtonCount'),
            Text('Watched percentage: $percentage%'),
            Text('Forward jumps at: ${_forwardJumps.map((d) => "${d.inSeconds}s").join(", ")}'),
            if (targetDuration != null)
              Text('Required (95%): ${(targetDuration * 0.95).toString()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _dispose() {
    _watchTimer?.cancel();
    _chewieCtrl?.dispose();
    _videoCtrl?.dispose();
    _youtubeCtrl?.dispose();
    _chewieCtrl = null;
    _videoCtrl = null;
    _youtubeCtrl = null;
    _isInitialized = false;
    _initError = false;
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show error state
    if (_initError) {
      return _buildErrorState();
    }

    // Show loading state
    if (!_isInitialized) {
      return _buildLoadingState();
    }

    // Show YouTube player
    if (_isYouTubeUrl) {
      if (kIsWeb && _youtubeId != null) {
        return _buildWebYouTubePlayer();
      } else if (_youtubeCtrl != null) {
        return _buildMobileYouTubePlayer();
      }
    }

    // Show regular video player
    if (!_isYouTubeUrl && _videoCtrl != null && _chewieCtrl != null) {
      return _buildRegularVideoPlayer();
    }

    // Fallback loading state
    return _buildLoadingState();
  }

  Widget _buildErrorState() {
    return Container(
      height: 200,
      color: Colors.black12,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Unable to load video',
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      color: Colors.black12,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildWebYouTubePlayer() {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_filled, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'YouTube Video',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Video ID: $_youtubeId',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton.small(
                  onPressed: _testMarkAsCompleted,
                  child: const Icon(Icons.check),
                  tooltip: 'Mark as completed (Test)',
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  onPressed: _showWatchStats,
                  child: const Icon(Icons.analytics),
                  tooltip: 'Show watch statistics',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileYouTubePlayer() {
    return Stack(
      children: [
        Container(
          color: Colors.black,
          child: YoutubePlayer(
            controller: _youtubeCtrl!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.redAccent,
            progressColors: const ProgressBarColors(
              playedColor: Colors.redAccent,
              handleColor: Colors.redAccent,
            ),
            onEnded: (data) {
              debugPrint('📱 YouTube video ended - evaluating completion');
              _evaluateCompletion();
            },
          ),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: Column(
            children: [
              FloatingActionButton.small(
                onPressed: _testMarkAsCompleted,
                child: const Icon(Icons.check),
                tooltip: 'Mark as completed (Test)',
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                onPressed: _showWatchStats,
                child: const Icon(Icons.analytics),
                tooltip: 'Show watch statistics',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegularVideoPlayer() {
    final aspect = _videoCtrl!.value.isInitialized && _videoCtrl!.value.size.width > 0
        ? _videoCtrl!.value.aspectRatio
        : 16 / 9;

    return Stack(
      children: [
        GestureDetector(
          onHorizontalDragStart: (_) => _handleDragStart(),
          onHorizontalDragEnd: (_) => _handleDragEnd(),
          child: AspectRatio(
            aspectRatio: aspect,
            child: Chewie(controller: _chewieCtrl!),
          ),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: Column(
            children: [
              FloatingActionButton.small(
                onPressed: _testMarkAsCompleted,
                child: const Icon(Icons.check),
                tooltip: 'Mark as completed (Test)',
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                onPressed: _showWatchStats,
                child: const Icon(Icons.analytics),
                tooltip: 'Show watch statistics',
              ),
            ],
          ),
        ),
      ],
    );
  }
}