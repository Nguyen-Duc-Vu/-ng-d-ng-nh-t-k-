import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/diary_entry.dart';
import '../services/hive_service.dart';
import '../routes/app_routes.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  bool _isSelecting = false;
  final Set<String> _selected = {};

  String _formatDate(DateTime d) {
    const months = ['Th1','Th2','Th3','Th4','Th5','Th6',
      'Th7','Th8','Th9','Th10','Th11','Th12'];
    return '${d.day} ${months[d.month - 1]}, ${d.year}';
  }

  void _enterSelectMode(String firstId) {
    setState(() {
      _isSelecting = true;
      _selected.add(firstId);
    });
  }

  void _exitSelectMode() {
    setState(() {
      _isSelecting = false;
      _selected.clear();
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _selectAll(List<DiaryEntry> favorites) {
    setState(() => _selected.addAll(favorites.map((e) => e.id)));
  }

  // ✅ Xoá tất cả favorites (nút thùng rác trên AppBar)
  void _confirmClearAll(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2A2420) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Xoá tất cả yêu thích?', style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF2C1810),
        )),
        content: Text('Tất cả bài viết sẽ bị bỏ khỏi danh sách yêu thích.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Huỷ', style: TextStyle(color: Colors.grey.shade500)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _clearAllFavorites();
            },
            child: const Text('Xoá tất cả',
                style: TextStyle(color: Color(0xFFE57373), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _clearAllFavorites() {
    final favorites = HiveService.getFavorites();
    for (final entry in favorites) {
      entry.isFavorite = false;
      entry.save();
    }
    _exitSelectMode();
  }

  // ✅ Xoá các mục đã chọn
  void _confirmDeleteSelected(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2A2420) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Bỏ ${_selected.length} bài khỏi yêu thích?', style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF2C1810),
        )),
        content: Text('Các bài viết sẽ bị bỏ khỏi danh sách yêu thích.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Huỷ', style: TextStyle(color: Colors.grey.shade500)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeSelectedFromFavorites();
            },
            child: const Text('Bỏ yêu thích',
                style: TextStyle(color: Color(0xFFE57373), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _removeSelectedFromFavorites() {
    for (final id in _selected) {
      final all = HiveService.getAllEntries();
      final entry = all.firstWhere((e) => e.id == id, orElse: () => throw Exception());
      entry.isFavorite = false;
      entry.save();
    }
    _exitSelectMode();
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
          _isSelecting ? 'Chọn bài viết' : 'Yêu thích',
          style: TextStyle(
            fontWeight: FontWeight.w700, fontSize: 20,
            color: isDark ? Colors.white : const Color(0xFF2C1810),
          ),
        ),
        actions: [
          ValueListenableBuilder(
            valueListenable: HiveService.box.listenable(),
            builder: (context, box, _) {
              final favorites = HiveService.getFavorites();
              if (favorites.isEmpty) return const SizedBox.shrink();

              if (_isSelecting) {
                // Khi đang select: nút tick xanh để thoát
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: _exitSelectMode,
                    child: Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4A90D9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                );
              }

              // Bình thường: nút xoá tất cả
              return IconButton(
                onPressed: () => _confirmClearAll(context),
                icon: const Icon(Icons.delete_sweep_rounded),
                color: const Color(0xFFE57373),
                tooltip: 'Xoá tất cả',
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: HiveService.box.listenable(),
        builder: (context, box, _) {
          final favorites = HiveService.getFavorites();
          if (favorites.isEmpty) return _buildEmpty();

          return Stack(
            children: [
              Column(
                children: [
                  // ✅ "Chọn tất cả" bar khi đang select
                  if (_isSelecting)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: GestureDetector(
                        onTap: () => _selectAll(favorites),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.select_all_rounded,
                                  size: 18,
                                  color: isDark ? Colors.white70 : Colors.black54),
                              const SizedBox(width: 8),
                              Text('Chọn tất cả (${favorites.length})',
                                  style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),

                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      itemCount: favorites.length,
                      itemBuilder: (_, i) {
                        final e = favorites[i];
                        final isSelected = _selected.contains(e.id);
                        return GestureDetector(
                          onTap: () {
                            if (_isSelecting) {
                              _toggleSelect(e.id);
                            } else {
                              Navigator.pushNamed(context, AppRoutes.detail, arguments: e);
                            }
                          },
                          onLongPress: () => _enterSelectMode(e.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE57373).withValues(alpha: isDark ? 0.2 : 0.1)
                                  : isDark ? const Color(0xFF2A2420) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFE57373)
                                    : isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : const Color(0xFFEDE5D8),
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.3)
                                      : const Color(0xFFB5835A).withValues(alpha: 0.08),
                                  blurRadius: 16, offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // ✅ Checkbox
                                if (_isSelecting) ...[
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 24, height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? const Color(0xFFE57373)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFE57373)
                                            : Colors.grey.shade400,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 14)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                ],

                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE57373).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(child: Text(e.mood,
                                      style: const TextStyle(fontSize: 24))),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.title, style: TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 15,
                                        color: isDark ? Colors.white : const Color(0xFF2C1810),
                                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text(_formatDate(e.date), style: TextStyle(
                                        fontSize: 11,
                                        color: const Color(0xFFB5835A).withValues(alpha: 0.8),
                                      )),
                                      if (e.content.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(e.content, maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12, color: Colors.grey.shade500,
                                            )),
                                      ],
                                    ],
                                  ),
                                ),
                                if (!_isSelecting)
                                  const Icon(Icons.favorite_rounded,
                                      color: Color(0xFFE57373), size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // ✅ Bottom toolbar khi đang select
              if (_isSelecting)
                Positioned(
                  bottom: 24, left: 32, right: 32,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20, offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Bỏ yêu thích (bookmark off)
                        GestureDetector(
                          onTap: _selected.isEmpty ? null : () => _confirmDeleteSelected(context),
                          child: Icon(Icons.bookmark_remove_rounded,
                              color: _selected.isEmpty
                                  ? Colors.grey.shade500
                                  : const Color(0xFFE57373),
                              size: 28),
                        ),
                        // Xoá hẳn khỏi app
                        GestureDetector(
                          onTap: _selected.isEmpty ? null : () async {
                            for (final id in _selected.toList()) {
                              await HiveService.deleteEntry(id);
                            }
                            _exitSelectMode();
                          },
                          child: Icon(Icons.delete_outline_rounded,
                              color: _selected.isEmpty
                                  ? Colors.grey.shade500
                                  : Colors.red,
                              size: 28),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border_rounded, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Chưa có bài yêu thích nào',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade400)),
          const SizedBox(height: 8),
          Text('Nhấn ··· trên bài viết để thêm vào yêu thích',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
#



