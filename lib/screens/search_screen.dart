import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import '../services/hive_service.dart';
import 'detail_screen.dart';
//Tìm kiếm bài nhật ký theo từ khóa
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<DiaryEntry> _filtered = [];
  final _controller = TextEditingController();
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String keyword) {
    // Load lại mỗi lần gõ để có dữ liệu mới nhất
    final all = HiveService.getAllEntries();
    setState(() {
      _hasSearched = keyword.isNotEmpty;
      _filtered = keyword.isEmpty
          ? []
          : all.where((e) {
        final k = keyword.toLowerCase();
        return e.title.toLowerCase().contains(k) ||
            e.content.toLowerCase().contains(k);
      }).toList();
    });
  }

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
          'Tìm kiếm',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF2C1810),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _controller,
              onChanged: _search,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm nhật ký...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFFB5835A)),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _controller.clear();
                    _search('');
                  },
                )
                    : null,
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFFEDE5D8),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: Color(0xFFB5835A), width: 1.5),
                ),
              ),
            ),
          ),
          Expanded(
            child: !_hasSearched
                ? _buildIdleState()
                : _filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filtered.length,
              itemBuilder: (_, i) =>
                  _SearchCard(
                    entry: _filtered[i],
                    formatDate: _formatDate,
                    isDark: isDark,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Nhập từ khóa để tìm kiếm',
            style: TextStyle(
                fontSize: 15, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Không tìm thấy kết quả',
            style: TextStyle(
                fontSize: 15, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  final DiaryEntry entry;
  final String Function(DateTime) formatDate;
  final bool isDark;

  const _SearchCard({
    required this.entry,
    required this.formatDate,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(entry: entry)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2420) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFEDE5D8),
          ),
        ),
        child: Row(
          children: [
            Text(entry.mood,
                style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF2C1810),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatDate(entry.date),
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFFB5835A)
                          .withValues(alpha: 0.8),
                    ),
                  ),
                  if (entry.content.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      entry.content,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}