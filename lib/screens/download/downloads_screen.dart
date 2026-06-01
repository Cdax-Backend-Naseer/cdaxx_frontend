import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/download_ledger_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_video_player.dart';


class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final DownloadLedgerService _ledgerService = DownloadLedgerService();
  Map<String, Map<String, List<Map<String, dynamic>>>> _organizedDownloads = {};
  List<String> _courseNames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadedVideos();
  }

  Future<void> _loadDownloadedVideos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final validVideos = await _ledgerService.getAllValidVideos();

      // Organize: Course -> Module -> Videos
      final Map<String, Map<String, List<Map<String, dynamic>>>> organized = {};

      for (var video in validVideos) {
        final courseName = video['courseName'] ?? 'Unknown Course';
        final moduleName = video['moduleName'] ?? 'General';

        if (!organized.containsKey(courseName)) {
          organized[courseName] = {};
        }

        if (!organized[courseName]!.containsKey(moduleName)) {
          organized[courseName]![moduleName] = [];
        }

        organized[courseName]![moduleName]!.add(video);
      }

      setState(() {
        _organizedDownloads = organized;
        _courseNames = organized.keys.toList();
        _isLoading = false;
      });

      print('📱 Organized ${validVideos.length} videos into ${_courseNames.length} courses');
    } catch (e) {
      print('❌ Error loading downloads: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteVideo(String videoId, String videoTitle) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Download'),
        content: Text('Delete "$videoTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _ledgerService.deleteVideo(videoId);
              await _loadDownloadedVideos();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Video deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _playVideo(Map<String, dynamic> video) {
    final userProvider = context.read<UserProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppVideoPlayer(
          videoUrl: video['filePath'],
          videoId: video['videoId'],
          courseId: null,
          userId: userProvider.userId,
          videoTitle: video['title'],
          courseName: video['courseName'],
        ),
      ),
    ).then((_) => _loadDownloadedVideos());
  }

  String _formatExpiry(DateTime expiryDate) {
    final daysLeft = expiryDate.difference(DateTime.now()).inDays;
    if (daysLeft <= 0) return 'Expired';
    if (daysLeft == 1) return '1 day left';
    return '$daysLeft days left';
  }

  Color _getExpiryColor(DateTime expiryDate) {
    final daysLeft = expiryDate.difference(DateTime.now()).inDays;
    if (daysLeft <= 3) return Colors.red;
    if (daysLeft <= 7) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'My Downloads',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF020617),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDownloadedVideos,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
      );
    }

    if (_courseNames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_done, size: 80, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'No downloads yet',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Download videos to watch offline',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _courseNames.length,
      itemBuilder: (context, courseIndex) {
        final courseName = _courseNames[courseIndex];
        final modules = _organizedDownloads[courseName]!;
        final moduleNames = modules.keys.toList();

        // Calculate total downloads for this course
        int totalDownloads = 0;
        for (var videos in modules.values) {
          totalDownloads += videos.length;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            collapsedBackgroundColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            title: Row(
              children: [
                const Icon(Icons.school, color: Color(0xFF38BDF8), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$totalDownloads video${totalDownloads != 1 ? 's' : ''} downloaded',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            children: moduleNames.map((moduleName) {
              final videos = modules[moduleName]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.folder, color: Color(0xFF38BDF8), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          moduleName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${videos.length})',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...videos.map((video) => _buildVideoItem(video)),
                  const Divider(
                    color: Colors.white24,
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildVideoItem(Map<String, dynamic> video) {
    final videoTitle = video['title'] ?? 'Unknown Video';
    final videoId = video['videoId'];
    final expiryDate = DateTime.parse(video['expiryDate']);
    final expiryColor = _getExpiryColor(expiryDate);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF38BDF8).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.play_arrow, color: Color(0xFF38BDF8)),
      ),
      title: Text(
        videoTitle,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _formatExpiry(expiryDate),
        style: TextStyle(color: expiryColor, fontSize: 12),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white54),
        onSelected: (value) async {
          if (value == 'delete') {
            await _deleteVideo(videoId, videoTitle);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red, size: 20),
                SizedBox(width: 12),
                Text('Delete'),
              ],
            ),
          ),
        ],
      ),
      onTap: () => _playVideo(video),
    );
  }
}