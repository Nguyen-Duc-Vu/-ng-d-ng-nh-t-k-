import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/diary_entry.dart';
import '../services/hive_service.dart';
import '../routes/app_routes.dart';   // ← Đảm bảo import này tồn tại
//Hiển thị chi tiết một bài nhật ký
class DetailScreen extends StatefulWidget {
  final DiaryEntry entry;
  const DetailScreen({super.key, required this.entry});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final videoPath = widget.entry.videoPath;
    if (videoPath != null && videoPath.isNotEmpty) {
      _videoController = VideoPlayerController.file(File(videoPath));
      await _videoController!.initialize();
      _videoController!.addListener(() {
        if (mounted) setState(() {});
      });
      setState(() => _videoInitialized = true);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAF7F2);
    final entry = widget.entry;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.arrow_back_rounded,
                size: 18,
                color: isDark ? Colors.white : const Color(0xFF2C1810)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // ==================== NÚT EDIT ====================
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFB5835A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_rounded,
                  size: 18, color: Color(0xFFB5835A)),
            ),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                AppRoutes.edit,
                arguments: entry,
              );
              if (result == 'updated' && mounted) {
                Navigator.pop(context, 'updated');
              }
            },
          ),

          // ==================== NÚT XÓA ====================
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  size: 18, color: Colors.red),
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text('Xóa nhật ký?',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  content: const Text('Hành động này không thể hoàn tác.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Xóa',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await HiveService.deleteEntry(entry.id);
                if (mounted) Navigator.pop(context, 'deleted');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mood + date
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB5835A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(entry.mood,
                      style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(entry.date),
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFFB5835A).withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.date.hour.toString().padLeft(2, '0')}:${entry.date.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ],
                ),
                const Spacer(),
                if (entry.isFavorite)
                  const Icon(Icons.favorite_rounded,
                      color: Color(0xFFE57373), size: 20),
              ],
            ),

            const SizedBox(height: 24),

            // Tiêu đề
            Text(
              entry.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF2C1810),
                letterSpacing: -0.5,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              height: 2,
              width: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFB5835A),
                borderRadius: BorderRadius.circular(1),
              ),
            ),

            const SizedBox(height: 16),

            // Nội dung
            Text(
              entry.content.isEmpty
                  ? '(Không có nội dung)'
                  : entry.content,
              style: TextStyle(
                fontSize: 16,
                height: 1.8,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.8)
                    : const Color(0xFF4A3728),
              ),
            ),

            // Ảnh đính kèm
            if (entry.imagePath != null && entry.imagePath!.isNotEmpty) ...[
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(entry.imagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: Colors.grey, size: 40),
                    ),
                  ),
                ),
              ),
            ],

            // Video đính kèm
            if (entry.videoPath != null && entry.videoPath!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildLabel('Video đính kèm', isDark),
              const SizedBox(height: 10),
              _videoInitialized && _videoController != null
                  ? _buildVideoPlayer(isDark)
                  : Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFB5835A),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(bool isDark) {
    final controller = _videoController!;
    final position = controller.value.position;
    final duration = controller.value.duration;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Color(0xFFB5835A),
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.white12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _formatDuration(position),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                    const Text(' / ',
                        style: TextStyle(
                            color: Colors.white38, fontSize: 12)),
                    Text(
                      _formatDuration(duration),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        controller.seekTo(Duration.zero);
                        controller.play();
                        setState(() => _isPlaying = true);
                      },
                      child: const Icon(Icons.replay_rounded,
                          color: Colors.white70, size: 22),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        if (controller.value.isPlaying) {
                          controller.pause();
                          setState(() => _isPlaying = false);
                        } else {
                          controller.play();
                          setState(() => _isPlaying = true);
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFB5835A),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          controller.value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark
            ? Colors.white.withValues(alpha: 0.5)
            : Colors.grey.shade600,
      ),
    );
  }
}