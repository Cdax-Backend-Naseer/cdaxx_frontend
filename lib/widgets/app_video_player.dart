import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/http_service.dart';
import '/config/environment_config.dart';

class AppVideoPlayer extends StatefulWidget {
  const AppVideoPlayer({
    super.key,
    required this.videoUrl,
    this.videoId,
    this.courseId,
    this.moduleId,
    this.userId,
    this.videoDuration,
    this.onVideoCompleted,
    this.minimumWatchPercentage = 0.70,
    this.maximumSkipPercentage = 0.20,
    this.minimumValidSegmentDuration = 5,
  });

  final String videoUrl;
  final String? videoId;
  final String? courseId;
  final String? moduleId;
  final String? userId;
  final Duration? videoDuration;
  final VoidCallback? onVideoCompleted;
  final double minimumWatchPercentage;
  final double maximumSkipPercentage;
  final int minimumValidSegmentDuration;

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
  bool _isMarkingAsCompleted = false;
  DateTime? _lastCompletionCheckTime;
  bool _videoMarkedAsCompleted = false;
  final HttpService _httpService = HttpService();

  // Tracking variables
  Duration _totalWatchTime = Duration.zero;
  DateTime? _videoStartTime;
  int _consecutiveForwardJumps = 0;
  List<Map<String, dynamic>> _playbackSegments = [];
  Timer? _playbackTimer;
  bool _isSegmentValid = true;
  Map<String, Duration> _watchedSegments = {};
  bool _suspectCheating = false;
  double _minimumRequiredWatchPercentage = 0.70;
  double _maximumSkipPercentage = 0.20;

  // For detecting seeks
  List<Duration> _recentPositions = [];
  static const int _maxPositionHistory = 10;
  static const Duration _rapidSeekThreshold = Duration(milliseconds: 500);
  DateTime? _lastSeekDetectionTime;
  bool _isSeeking = false;

  // Position tracking
  int _forwardButtonCount = 0;
  Duration _lastPosition = Duration.zero;
  Duration? _actualVideoDuration;
  DateTime? _lastProgressUpdateTime;
  List<Duration> _forwardJumps = [];

  // Playback quality tracking
  int _validWatchSegments = 0;
  int _totalSegments = 0;

  // Warning tracking
  bool _warningShownForCurrentSession = false;
  DateTime? _lastWarningTime;
  static const int _minTimeBetweenWarnings = 10;

  // Session tracking
  DateTime? _sessionStartTime;

  @override
  void initState() {
    super.initState();
    _minimumRequiredWatchPercentage = widget.minimumWatchPercentage;
    _maximumSkipPercentage = widget.maximumSkipPercentage;
    _sessionStartTime = DateTime.now();
    _initialize();
  }

  @override
  void didUpdateWidget(AppVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl ||
        oldWidget.videoId != widget.videoId) {
      _resetTracking();
      _dispose();
      _initialize();
    }
  }

  void _resetTracking() {
    debugPrint('🔄 Resetting ALL tracking variables');

    _videoMarkedAsCompleted = false;
    _forwardButtonCount = 0;
    _lastPosition = Duration.zero;
    _forwardJumps.clear();
    _lastProgressUpdateTime = null;

    // Reset enhanced tracking
    _totalWatchTime = Duration.zero;
    _videoStartTime = null;
    _consecutiveForwardJumps = 0;
    _playbackSegments.clear();
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _isSegmentValid = true;
    _watchedSegments.clear();
    _suspectCheating = false;
    _recentPositions.clear();
    _isSeeking = false;
    _lastSeekDetectionTime = null;
    _validWatchSegments = 0;
    _totalSegments = 0;

    // Reset debouncing variables
    _isMarkingAsCompleted = false;
    _lastCompletionCheckTime = null;

    // Reset warning tracking
    _warningShownForCurrentSession = false;
    _lastWarningTime = null;

    // Reset session time
    _sessionStartTime = DateTime.now();

    debugPrint('✅ Tracking reset complete');
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      final String? youtubeId = YoutubePlayer.convertUrlToId(widget.videoUrl);

      if (youtubeId != null) {
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
        final video = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
        await video.initialize();

        _actualVideoDuration = video.value.duration;
        debugPrint('🎬 Video duration: ${_actualVideoDuration?.inSeconds}s');

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

        _startEnhancedTracking(video);

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

  void _startEnhancedTracking(VideoPlayerController controller) {
    debugPrint('🎯 Starting fresh tracking session');
    _videoStartTime = DateTime.now();
    _sessionStartTime = DateTime.now();

    controller.addListener(() {
      if (!controller.value.isInitialized) return;

      final currentPosition = controller.value.position;
      final isPlaying = controller.value.isPlaying;

      _detectSeeking(currentPosition);
      _updateWatchedSegments(currentPosition, isPlaying);
      _trackPlaybackSegments(currentPosition, isPlaying);
      _checkForSuspiciousBehavior(currentPosition, isPlaying);
      _handleRegularVideoState(controller);
    });

    _playbackTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (controller.value.isPlaying) {
        _totalWatchTime += Duration(seconds: 1);
      }
    });
  }

  void _detectSeeking(Duration currentPosition) {
    final now = DateTime.now();

    _recentPositions.add(currentPosition);
    if (_recentPositions.length > _maxPositionHistory) {
      _recentPositions.removeAt(0);
    }

    if (_recentPositions.length >= 2) {
      final lastPosition = _recentPositions[_recentPositions.length - 2];
      final positionChange = (currentPosition - lastPosition).abs();
      final timeSinceLastChange = _lastSeekDetectionTime != null
          ? now.difference(_lastSeekDetectionTime!)
          : Duration(seconds: 10);

      if (positionChange.inSeconds > 5 &&
          timeSinceLastChange < _rapidSeekThreshold * 2) {
        if (!_isSeeking) {
          debugPrint('🎯 Seek detected: ${positionChange.inSeconds}s jump');
          _isSeeking = true;
          _isSegmentValid = false;
        }
        _lastSeekDetectionTime = now;
      } else if (positionChange.inSeconds <= 1 &&
          timeSinceLastChange > Duration(seconds: 2)) {
        _isSeeking = false;
      }
    }
  }

  void _updateWatchedSegments(Duration currentPosition, bool isPlaying) {
    if (!isPlaying || _isSeeking) return;

    final blockIndex = (currentPosition.inSeconds / 10).floor();
    final blockKey = 'block_${blockIndex * 10}_${(blockIndex + 1) * 10}';

    _watchedSegments.update(
      blockKey,
          (value) => value + Duration(seconds: 1),
      ifAbsent: () => Duration(seconds: 1),
    );
  }

  void _trackPlaybackSegments(Duration currentPosition, bool isPlaying) {
    final now = DateTime.now();

    if (isPlaying && !_isSeeking && _isSegmentValid) {
      if (_playbackSegments.isEmpty ||
          _playbackSegments.last['endPosition'] != null) {
        _playbackSegments.add({
          'startPosition': currentPosition,
          'startTime': now,
          'endPosition': null,
          'endTime': null,
          'valid': true,
        });
      }
    } else if (!isPlaying && _playbackSegments.isNotEmpty &&
        _playbackSegments.last['endPosition'] == null) {
      _playbackSegments.last['endPosition'] = currentPosition;
      _playbackSegments.last['endTime'] = now;

      final startPos = _playbackSegments.last['startPosition'] as Duration;
      final endPos = _playbackSegments.last['endPosition'] as Duration;
      final segmentDuration = endPos - startPos;

      _playbackSegments.last['valid'] = segmentDuration.inSeconds >= widget.minimumValidSegmentDuration;

      if (_playbackSegments.last['valid'] as bool) {
        _validWatchSegments++;
      }
      _totalSegments++;

      _isSegmentValid = true;
    }

    if (isPlaying && _playbackSegments.isNotEmpty &&
        _playbackSegments.last['endPosition'] == null) {
      final startPos = _playbackSegments.last['startPosition'] as Duration;
      final segmentDuration = currentPosition - startPos;

      if (segmentDuration.inSeconds >= 30) {
        _playbackSegments.last['endPosition'] = currentPosition;
        _playbackSegments.last['endTime'] = now;
        _playbackSegments.last['valid'] = true;
        _validWatchSegments++;
        _totalSegments++;

        _playbackSegments.add({
          'startPosition': currentPosition,
          'startTime': now,
          'endPosition': null,
          'endTime': null,
          'valid': true,
        });
      }
    }
  }

  void _checkForSuspiciousBehavior(Duration currentPosition, bool isPlaying) {
    if (_actualVideoDuration == null) return;

    final totalDuration = _actualVideoDuration!.inSeconds;
    if (totalDuration == 0) return;

    final totalPossibleBlocks = (totalDuration / 10).ceil();
    final watchedBlockPercentage = totalPossibleBlocks > 0
        ? _watchedSegments.length / totalPossibleBlocks
        : 0.0;

    final jumpRatio = totalDuration > 0
        ? _forwardButtonCount / max(1, totalDuration ~/ 60)
        : 0.0;

    if (_suspectCheating) {
      final hasWatchedSignificantly = watchedBlockPercentage > _minimumRequiredWatchPercentage * 0.7;
      final hasNoRecentJumps = _forwardButtonCount == 0 ||
          (DateTime.now().difference(_videoStartTime ?? DateTime.now()).inSeconds > 30);
      final isWatchingContinuously = isPlaying && !_isSeeking;

      if (hasWatchedSignificantly && hasNoRecentJumps && isWatchingContinuously) {
        debugPrint('✅ User resumed proper watching - resetting suspicion');
        _suspectCheating = false;
        _warningShownForCurrentSession = false;
      }
    }

    final newSuspiciousBehavior = (
        _totalWatchTime.inSeconds > totalDuration * 0.3 &&
            watchedBlockPercentage < _minimumRequiredWatchPercentage * 0.3
    ) ||
        jumpRatio > 5.0 ||
        _consecutiveForwardJumps > 10 ||
        (_totalSegments > 5 && _validWatchSegments < _totalSegments * 0.2) ||
        _isSeeking;

    if (newSuspiciousBehavior && !_suspectCheating) {
      _suspectCheating = true;
      debugPrint('⚠️ New suspicious behavior detected');
    }
  }

  void _handleRegularVideoState(VideoPlayerController controller) {
    if (!controller.value.isInitialized) return;

    final currentPosition = controller.value.position;
    final isPlaying = controller.value.isPlaying;

    if (!isPlaying && currentPosition.inSeconds >= (_actualVideoDuration?.inSeconds ?? 0) * 0.99) {
      debugPrint('🎬 Video ended detected at ${currentPosition.inSeconds}s');
      _trackPlaybackSegments(currentPosition, false);
      _checkForCompletion(currentPosition, false);
    }

    if (_lastPosition.inSeconds > 0 && !_isSeeking) {
      final jump = currentPosition - _lastPosition;

      if (jump.inSeconds >= 10) {
        _forwardButtonCount++;
        _forwardJumps.add(currentPosition);

        if (jump.inSeconds >= 10 && _lastPosition.inSeconds > 0) {
          final timeSinceLastJump = _forwardJumps.length > 1
              ? currentPosition - _forwardJumps[_forwardJumps.length - 2]
              : Duration(minutes: 5);

          if (timeSinceLastJump.inSeconds < 30) {
            _consecutiveForwardJumps++;
          } else {
            _consecutiveForwardJumps = 1;
          }
        }

        if (_actualVideoDuration != null &&
            currentPosition.inSeconds > _actualVideoDuration!.inSeconds * 0.9 &&
            jump.inSeconds > _actualVideoDuration!.inSeconds * 0.3) {
          _isSegmentValid = false;
        }
      }

      if (jump.inSeconds <= -10) {
        debugPrint('⏪ Rewind detected: ${jump.abs().inSeconds}s');
        _consecutiveForwardJumps = 0;
        if (_warningShownForCurrentSession) {
          _warningShownForCurrentSession = false;
        }
      }
    }

    _lastPosition = currentPosition;

    final now = DateTime.now();
    if (_lastProgressUpdateTime == null ||
        now.difference(_lastProgressUpdateTime!).inSeconds >= 10) {
      _sendProgressUpdate();
      _lastProgressUpdateTime = now;
    }

    _checkForCompletion(currentPosition, isPlaying);
  }

  void _checkForCompletion(Duration currentPosition, bool isPlaying) {
    if (_actualVideoDuration == null || _videoMarkedAsCompleted) return;

    final videoDuration = _actualVideoDuration!;
    final isNearEnd = currentPosition.inSeconds >= videoDuration.inSeconds * 0.95;

    if (!isNearEnd) return;

    final now = DateTime.now();
    if (_lastCompletionCheckTime != null &&
        now.difference(_lastCompletionCheckTime!).inSeconds < 2) {
      return;
    }
    _lastCompletionCheckTime = now;

    final timeSinceSessionStart = _sessionStartTime != null
        ? now.difference(_sessionStartTime!).inSeconds
        : 0;

    final minimumSessionTime = max(videoDuration.inSeconds * 0.8, 5.0).toInt();

    if (timeSinceSessionStart < minimumSessionTime) {
      debugPrint('⏰ Not enough session time: $timeSinceSessionStart/$minimumSessionTime seconds');
      return;
    }

    final totalWatchedBlocks = _watchedSegments.length;
    final totalPossibleBlocks = (videoDuration.inSeconds / 10).ceil();
    final watchedBlockPercentage = totalPossibleBlocks > 0
        ? totalWatchedBlocks / totalPossibleBlocks
        : 0.0;

    Duration totalValidWatchTime = Duration.zero;
    for (final segment in _playbackSegments) {
      if (segment['valid'] == true) {
        final startPos = segment['startPosition'] as Duration;
        final endPos = segment['endPosition'] as Duration? ?? currentPosition;
        totalValidWatchTime += endPos - startPos;
      }
    }

    final continuousWatchPercentage = videoDuration.inSeconds > 0
        ? totalValidWatchTime.inSeconds / videoDuration.inSeconds
        : 0.0;

    final requirementsMet =
        !_suspectCheating &&
            !_isSeeking &&
            watchedBlockPercentage >= _minimumRequiredWatchPercentage * 0.7 &&
            continuousWatchPercentage >= _minimumRequiredWatchPercentage * 0.5 &&
            _consecutiveForwardJumps <= 5 &&
            (_totalSegments == 0 || _validWatchSegments >= max(1, _totalSegments * 0.3)) &&
            (isPlaying || currentPosition.inSeconds >= videoDuration.inSeconds * 0.98) &&
            timeSinceSessionStart >= minimumSessionTime;

    debugPrint('📊 Completion Check:');
    debugPrint('   ├─ Requirements met: $requirementsMet');
    debugPrint('   ├─ Suspect cheating: $_suspectCheating');

    if (requirementsMet) {
      _markVideoAsCompleted();
    } else if (isNearEnd && !_videoMarkedAsCompleted) {
      final shouldShowWarning = !_warningShownForCurrentSession &&
          (_lastWarningTime == null ||
              now.difference(_lastWarningTime!).inSeconds > _minTimeBetweenWarnings);

      if (shouldShowWarning) {
        _showCompletionWarning();
        _warningShownForCurrentSession = true;
        _lastWarningTime = now;
      }
    }
  }

  void _showCompletionWarning() {
    if (_videoMarkedAsCompleted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    final snackBar = SnackBar(
      content: const Text('Please watch more of the video to mark it as completed'),
      backgroundColor: Colors.orange,
      duration: Duration(seconds: 5),
      action: SnackBarAction(
        label: 'DETAILS',
        textColor: Colors.white,
        onPressed: () {
          _showWatchStats();
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _handleYouTubeVideoState(YoutubePlayerController controller) {
    if (!controller.value.isReady) return;

    final currentPosition = controller.value.position;
    final playerState = controller.value.playerState;

    if (_lastPosition.inSeconds > 0) {
      final jump = currentPosition - _lastPosition;

      if (jump.inSeconds >= 30) {
        _forwardButtonCount++;
        _forwardJumps.add(currentPosition);

        if (_forwardJumps.length > 1) {
          final lastJumpTime = _forwardJumps[_forwardJumps.length - 2];
          if (currentPosition - lastJumpTime < Duration(seconds: 30)) {
            _consecutiveForwardJumps++;
          }
        }

        if (jump.inSeconds > 60) {
          _suspectCheating = true;
        }
      }
    }

    _lastPosition = currentPosition;

    if (playerState == PlayerState.playing) {
      final blockIndex = (currentPosition.inSeconds / 10).floor();
      final blockKey = 'block_${blockIndex * 10}_${(blockIndex + 1) * 10}';
      _watchedSegments.update(
        blockKey,
            (value) => value + Duration(seconds: 1),
        ifAbsent: () => Duration(seconds: 1),
      );
    }

    final now = DateTime.now();
    if (_lastProgressUpdateTime == null ||
        now.difference(_lastProgressUpdateTime!).inSeconds >= 10) {
      _sendProgressUpdate();
      _lastProgressUpdateTime = now;
    }

    if (playerState == PlayerState.ended && !_videoMarkedAsCompleted) {
      _checkYouTubeCompletion();
    }
  }

  void _checkYouTubeCompletion() {
    if (_actualVideoDuration == null) {
      _actualVideoDuration = widget.videoDuration;
    }

    if (_actualVideoDuration == null) {
      if (!_suspectCheating && _forwardButtonCount <= 5) {
        _markVideoAsCompleted();
      }
      return;
    }

    final videoDuration = _actualVideoDuration!;
    final totalWatchedBlocks = _watchedSegments.length;
    final totalPossibleBlocks = (videoDuration.inSeconds / 10).ceil();
    final watchedBlockPercentage = totalWatchedBlocks / totalPossibleBlocks;

    final requirementsMet =
        !_suspectCheating &&
            watchedBlockPercentage >= _minimumRequiredWatchPercentage * 0.9 &&
            _consecutiveForwardJumps <= 4 &&
            _forwardButtonCount <= (videoDuration.inSeconds / 60).ceil() * 2;

    if (requirementsMet) {
      _markVideoAsCompleted();
    } else if (!_videoMarkedAsCompleted) {
      final now = DateTime.now();
      final shouldShowWarning = !_warningShownForCurrentSession &&
          (_lastWarningTime == null ||
              now.difference(_lastWarningTime!).inSeconds > _minTimeBetweenWarnings);

      if (shouldShowWarning) {
        _showCompletionWarning();
        _warningShownForCurrentSession = true;
        _lastWarningTime = now;
      }
    }
  }

  // FIXED: Send progress updates with isCompleted flag when video is completed
  Future<void> _sendProgressUpdate() async {
    if (widget.videoId == null || widget.userId == null) return;

    try {
      final videoId = int.tryParse(widget.videoId!);
      final userId = int.tryParse(widget.userId!);

      if (videoId == null || userId == null) return;

      final currentPosition = _isYouTubeUrl
          ? (_youtubeCtrl?.value.position ?? Duration.zero)
          : (_videoCtrl?.value.position ?? Duration.zero);

      final totalWatchedBlocks = _watchedSegments.length;
      final totalPossibleBlocks = _actualVideoDuration != null
          ? (_actualVideoDuration!.inSeconds / 10).ceil()
          : 0;
      final watchQuality = totalPossibleBlocks > 0
          ? totalWatchedBlocks / totalPossibleBlocks
          : 0.0;

      // Calculate progress percentage based on video duration
      final progressPercentage = _actualVideoDuration != null && _actualVideoDuration!.inSeconds > 0
          ? min(currentPosition.inSeconds / _actualVideoDuration!.inSeconds * 100, 100.0)
          : 0.0;

      final progressData = {
        'userId': userId,
        'watchedSeconds': currentPosition.inSeconds,
        'lastPositionSeconds': currentPosition.inSeconds,
        'forwardJumpsCount': _forwardButtonCount,
        'consecutiveJumps': _consecutiveForwardJumps,
        'totalWatchTime': _totalWatchTime.inSeconds,
        'watchQuality': watchQuality,
        'watchedBlocks': totalWatchedBlocks,
        'suspectCheating': _suspectCheating,
        'currentlySeeking': _isSeeking,
        'progressPercentage': progressPercentage, // NEW: Add progress percentage
        'isCompleted': _videoMarkedAsCompleted, // NEW: Add completion status
        'completedAt': _videoMarkedAsCompleted ? DateTime.now().toIso8601String() : null, // NEW: Completion timestamp
        'playbackSegments': _playbackSegments.map((segment) => ({
          'startPosition': (segment['startPosition'] as Duration).inSeconds,
          'endPosition': (segment['endPosition'] as Duration?)?.inSeconds,
          'startTime': (segment['startTime'] as DateTime).toIso8601String(),
          'endTime': (segment['endTime'] as DateTime?)?.toIso8601String(),
          'valid': segment['valid'],
        })).toList(),
      };

      final response = await _httpService.post<Map<String, dynamic>>(
        '/api/videos/$videoId/progress',
            (data) => data as Map<String, dynamic>,
        body: progressData,
      );

      if (response.isSuccess) {
        debugPrint('📊 Progress updated: ${progressPercentage.toStringAsFixed(1)}%');
      } else {
        debugPrint('❌ Progress update failed: ${response.errorMessage}');
      }
    } catch (e) {
      debugPrint('❌ Error updating progress: $e');
    }
  }

  // FIXED: Send final 100% progress update before marking as completed
  Future<void> _markVideoAsCompleted() async {
    if (_videoMarkedAsCompleted) {
      debugPrint('⏭️ Video already marked as completed - skipping');
      return;
    }

    if (_isMarkingAsCompleted) {
      debugPrint('⏭️ Already in process of marking video as completed - skipping');
      return;
    }

    _isMarkingAsCompleted = true;

    try {
      final videoId = int.tryParse(widget.videoId!);
      final userId = int.tryParse(widget.userId!);
      final courseId = int.tryParse(widget.courseId!);
      final moduleId = int.tryParse(widget.moduleId!);

      if (videoId == null || userId == null) {
        _isMarkingAsCompleted = false;
        return;
      }

      // STEP 1: Send FINAL progress update with 100% completion
      if (_actualVideoDuration != null) {
        debugPrint('📤 Sending final 100% progress update...');

        final totalPossibleBlocks = (_actualVideoDuration!.inSeconds / 10).ceil();

        final finalProgressData = {
          'userId': userId,
          'watchedSeconds': _actualVideoDuration!.inSeconds, // Full duration
          'lastPositionSeconds': _actualVideoDuration!.inSeconds, // At end
          'forwardJumpsCount': _forwardButtonCount,
          'consecutiveJumps': _consecutiveForwardJumps,
          'totalWatchTime': _totalWatchTime.inSeconds,
          'watchQuality': 1.0, // 100% quality
          'watchedBlocks': totalPossibleBlocks, // All blocks
          'suspectCheating': false, // Reset for completion
          'currentlySeeking': false,
          'progressPercentage': 100.0, // 100% progress
          'isCompleted': true, // Mark as completed
          'completedAt': DateTime.now().toIso8601String(), // Completion timestamp
          'playbackSegments': _playbackSegments.map((segment) => ({
            'startPosition': (segment['startPosition'] as Duration).inSeconds,
            'endPosition': (segment['endPosition'] as Duration?)?.inSeconds,
            'startTime': (segment['startTime'] as DateTime).toIso8601String(),
            'endTime': (segment['endTime'] as DateTime?)?.toIso8601String(),
            'valid': segment['valid'],
          })).toList(),
        };

        final progressResponse = await _httpService.post<Map<String, dynamic>>(
          '/api/videos/$videoId/progress',
              (data) => data as Map<String, dynamic>,
          body: finalProgressData,
        );

        if (progressResponse.isSuccess) {
          debugPrint('✅ Final 100% progress update sent successfully');
        } else {
          debugPrint('⚠️ Final progress update failed, but continuing with completion...');
        }
      }

      // STEP 2: Mark video as completed in the system
      debugPrint('📤 Marking video as completed in system...');

      String url = '/api/videos/$videoId/complete?userId=$userId';

      if (courseId != null) {
        url += '&courseId=$courseId';
      }
      if (moduleId != null) {
        url += '&moduleId=$moduleId';
      }

      final response = await _httpService.post<Map<String, dynamic>>(
        url,
            (data) => data as Map<String, dynamic>,
        body: {},
      );

      if (response.isSuccess && response.data != null) {
        final responseData = response.data!;
        if (responseData['success'] == true) {
          debugPrint('✅ Video $videoId marked as completed in system!');
          _videoMarkedAsCompleted = true;

          // Clear any warnings since video is now complete
          ScaffoldMessenger.of(context).clearSnackBars();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video completed! Progress saved.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }

          // Call completion callback
          widget.onVideoCompleted?.call();

          // Send one more progress update to ensure backend has latest state
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _sendProgressUpdate();
          });

        } else {
          debugPrint('❌ API returned error: ${responseData['error']}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${responseData['error']}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        debugPrint('❌ Failed to mark video complete: ${response.errorMessage}');

        if (response.statusCode == 400) {
          final responseBody = response.data;
          if (responseBody?['error']?.contains('already completed') ?? false ||
              responseBody?['error']?.contains('rollback-only') ?? false) {
            debugPrint('ℹ️ Video already completed or transaction issue');
            _videoMarkedAsCompleted = true;
            widget.onVideoCompleted?.call();
            _isMarkingAsCompleted = false;
            return;
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save progress: ${response.errorMessage}'),
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
    } finally {
      _isMarkingAsCompleted = false;
    }
  }

  void _showWatchStats() {
    final currentPosition = _isYouTubeUrl
        ? (_youtubeCtrl?.value.position ?? Duration.zero)
        : (_videoCtrl?.value.position ?? Duration.zero);

    final targetDuration = _actualVideoDuration ?? widget.videoDuration;

    final totalPossibleBlocks = targetDuration != null
        ? (targetDuration.inSeconds / 10).ceil()
        : 0;
    final watchedBlockPercentage = totalPossibleBlocks > 0
        ? (_watchedSegments.length / totalPossibleBlocks * 100).toStringAsFixed(1)
        : 'N/A';

    final progressPercentage = targetDuration != null && targetDuration.inSeconds > 0
        ? min(currentPosition.inSeconds / targetDuration.inSeconds * 100, 100.0).toStringAsFixed(1)
        : '0.0';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Watch Statistics'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('Current Position', '${currentPosition.inSeconds}s'),
              if (targetDuration != null)
                _buildStatRow('Total Duration', '${targetDuration.inSeconds}s'),
              _buildStatRow('Progress', '$progressPercentage%'),
              _buildStatRow('Total Watch Time', '${_totalWatchTime.inSeconds}s'),
              _buildStatRow('Forward Jumps', '$_forwardButtonCount'),
              _buildStatRow('Consecutive Jumps', '$_consecutiveForwardJumps'),
              _buildStatRow('Watched Blocks', '${_watchedSegments.length}/$totalPossibleBlocks ($watchedBlockPercentage%)'),
              _buildStatRow('Valid Segments', '$_validWatchSegments/$_totalSegments'),
              _buildStatRow('Currently Seeking', _isSeeking ? 'YES' : 'NO'),
              _buildStatRow('Suspicious Behavior', _suspectCheating ? 'YES ⚠️' : 'NO ✅'),
              _buildStatRow('Video Status', _videoMarkedAsCompleted ? 'COMPLETED ✅' : 'IN PROGRESS'),
              if (_sessionStartTime != null)
                _buildStatRow('Session Time', '${DateTime.now().difference(_sessionStartTime!).inSeconds}s'),
              const SizedBox(height: 10),
              const Text(
                'Completion Status:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              _buildTip(_videoMarkedAsCompleted
                  ? '✅ Video is marked as completed in system'
                  : '⏳ Video is still in progress'),
              _buildTip('Progress sent to backend: $progressPercentage%'),
              if (_videoMarkedAsCompleted)
                _buildTip('🎉 Streak should update on next calculation'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
          if (_suspectCheating)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _suspectCheating = false;
                _warningShownForCurrentSession = false;
                ScaffoldMessenger.of(context).clearSnackBars();
              },
              child: const Text('RESET WARNING'),
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(value),
          ],
        )
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 2),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  void _dispose() {
    debugPrint('♻️ Disposing video player and tracking');
    _playbackTimer?.cancel();
    _playbackTimer = null;
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
    if (_initError) return _buildErrorState();
    if (!_isInitialized) return _buildLoadingState();

    if (_isYouTubeUrl) {
      if (kIsWeb && _youtubeId != null) {
        return _buildWebYouTubePlayer();
      } else if (_youtubeCtrl != null) {
        return _buildMobileYouTubePlayer();
      }
    }

    if (!_isYouTubeUrl && _videoCtrl != null && _chewieCtrl != null) {
      return _buildRegularVideoPlayer();
    }

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
      child: Center(
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
    );
  }

  Widget _buildMobileYouTubePlayer() {
    return Container(
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
          _checkYouTubeCompletion();
        },
      ),
    );
  }

  Widget _buildRegularVideoPlayer() {
    final aspect = _videoCtrl!.value.isInitialized && _videoCtrl!.value.size.width > 0
        ? _videoCtrl!.value.aspectRatio
        : 16 / 9;

    return AspectRatio(
      aspectRatio: aspect,
      child: Chewie(controller: _chewieCtrl!),
    );
  }
}