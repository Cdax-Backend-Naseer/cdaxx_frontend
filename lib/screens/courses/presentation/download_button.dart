import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/secure_download_provider.dart';
import '../../../providers/user_provider.dart';

class DownloadButton extends StatefulWidget {
  final String videoId;
  final String videoUrl;
  final String courseId;
  final String? userId;
  final String videoTitle;
  final String courseName;
  final String moduleName;  // ADD THIS - required

  const DownloadButton({
    super.key,
    required this.videoId,
    required this.videoUrl,
    required this.courseId,
    this.userId,
    required this.videoTitle,
    required this.courseName,
    required this.moduleName,  // ADD THIS
  });

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  bool _isAlreadySaved = false;
  bool _checkingStatus = true;
  bool _canDownload = false;
  DateTime? _subscriptionEndDate;
  bool _isCheckingSubscription = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkOfflineStatus();
    await _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    if (_isCheckingSubscription) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = widget.userId ?? userProvider.userId;

    if (userId == null) {
      if (mounted) {
        setState(() {
          _canDownload = false;
          _checkingStatus = false;
        });
      }
      return;
    }

    _isCheckingSubscription = true;

    try {
      final downloadProvider = Provider.of<SecureDownloadProvider>(context, listen: false);

      final canDownload = await downloadProvider.canDownloadVideo(
        widget.videoId,
        widget.courseId,
        userId.toString(),
      );

      DateTime? endDate;
      if (canDownload) {
        endDate = await downloadProvider.getSubscriptionEndDate(
          widget.videoId,
          widget.courseId,
          userId.toString(),
        );
      }

      if (mounted) {
        setState(() {
          _canDownload = canDownload;
          _subscriptionEndDate = endDate;
        });
      }
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      if (mounted) {
        setState(() {
          _canDownload = false;
        });
      }
    } finally {
      _isCheckingSubscription = false;
      if (mounted) {
        setState(() {
          _checkingStatus = false;
        });
      }
    }
  }

  Future<void> _checkOfflineStatus() async {
    final provider = Provider.of<SecureDownloadProvider>(context, listen: false);
    final isSaved = await provider.isVideoDownloaded(widget.videoId);

    bool isValid = false;
    if (isSaved) {
      isValid = await provider.isDownloadedVideoValid(widget.videoId);
      if (!isValid) {
        await provider.removeDownloadedVideo(widget.videoId);
      }
    }

    if (mounted) {
      setState(() {
        _isAlreadySaved = isValid;
      });
    }
  }

  String _formatEndDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final now = DateTime.now();
    if (now.isAfter(date)) return 'Expired';
    final daysLeft = date.difference(now).inDays;
    if (daysLeft == 0) return 'today';
    if (daysLeft == 1) return 'tomorrow';
    return 'in $daysLeft days';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingStatus) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Consumer<SecureDownloadProvider>(
      builder: (context, downloadProvider, child) {
        final isDownloading = downloadProvider.isDownloading[widget.videoId] ?? false;
        final currentProgress = downloadProvider.downloadProgress[widget.videoId] ?? 0;

        if (isDownloading) {
          return Container(
            padding: const EdgeInsets.all(8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    value: currentProgress / 100,
                    color: Colors.green,
                    backgroundColor: Colors.grey.shade300,
                    strokeWidth: 3,
                  ),
                ),
                Text('$currentProgress%', style: const TextStyle(fontSize: 9)),
              ],
            ),
          );
        }

        if (_isAlreadySaved) {
          return IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
            onPressed: () => _showOptionsMenu(downloadProvider),
          );
        }

        if (!_canDownload) {
          return IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.grey, size: 28),
            onPressed: null,
          );
        }

        return IconButton(
          icon: const Icon(Icons.file_download_outlined, size: 28),
          onPressed: () async {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            final userId = widget.userId ?? userProvider.userId;

            if (userId == null) {
              _showSnackBar('Please login', isError: true);
              return;
            }

            print('🔽 DOWNLOADING WITH METADATA:');
            print('   ├─ videoTitle: ${widget.videoTitle}');
            print('   ├─ courseName: ${widget.courseName}');
            print('   ├─ moduleName: ${widget.moduleName}');
            print('   └─ videoId: ${widget.videoId}');

            final success = await downloadProvider.startSecureDownload(
              videoUrl: widget.videoUrl,
              videoId: widget.videoId,
              courseId: widget.courseId,
              userId: userId.toString(),
              videoTitle: widget.videoTitle,
              courseName: widget.courseName,
              moduleName: widget.moduleName,  // PASS MODULE NAME
            );

            if (!success) {
              _showSnackBar('Download failed', isError: true);
            }
            await _checkOfflineStatus();
          },
        );
      },
    );
  }

  void _showOptionsMenu(SecureDownloadProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Download Options'), leading: Icon(Icons.download)),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.pop(context);
                await provider.removeDownloadedVideo(widget.videoId);
                await _checkOfflineStatus();
              },
            ),
          ],
        ),
      ),
    );
  }
}