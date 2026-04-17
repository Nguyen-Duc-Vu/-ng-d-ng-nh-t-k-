import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/diary_entry.dart';
import '../services/hive_service.dart';
import '../routes/app_routes.dart';
//Hiển thị danh sách bài nhật ký yêu thích
class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  String _formatDate(DateTime d) {
    const months = [
      'Th1','Th2','Th3','Th4','Th5','Th6',
      'Th7','Th8','Th9','Th10','Th11','Th12'
    ];
    return '${d.day} ${months[d.month - 1]}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAF7F2);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Yêu thích',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: isDark ? Colors.white : const Color(0xFF2C1810),
          ),
        ),
      ),
      // ✅ ValueListenableBuilder tự động rebuild khi Hive thay đổi
      body: ValueListenableBuilder(
        valueListenable: HiveService.box.listenable(),
        builder: (context, box, _) {
          final favorites = HiveService.getFavorites();
          return favorites.isEmpty
              ? _buildEmpty()
              : _buildList(favorites, isDark, context);
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border_rounded,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Chưa có bài yêu thích nào',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn ··· trên bài viết để thêm vào yêu thích',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildList(
      List<DiaryEntry> favorites, bool isDark, BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: favorites.length,
      itemBuilder: (_, i) {
        final e = favorites[i];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.detail,
            arguments: e,
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2420) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFEDE5D8),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : const Color(0xFFB5835A).withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE57373).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(e.mood,
                        style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF2C1810),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(e.date),
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFFB5835A)
                              .withValues(alpha: 0.8),
                        ),
                      ),
                      if (e.content.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          e.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.favorite_rounded,
                    color: Color(0xFFE57373), size: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}