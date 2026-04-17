import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'favorite_screen.dart';
import '../services/hive_service.dart';
import '../routes/app_routes.dart';
//Trang chủ – hiển thị danh sách nhật ký
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  List<DiaryEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  void _loadEntries() {
    setState(() => _entries = HiveService.getAllEntries());
  }

  void _addEntry(DiaryEntry entry) async {
    await HiveService.addEntry(entry);
    _loadEntries();
  }

  void _deleteEntry(String id) async {
    await HiveService.deleteEntry(id);
    _loadEntries();
  }

  void _toggleFavorite(String id) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      final entry = _entries[index];
      entry.isFavorite = !entry.isFavorite;
      await HiveService.updateEntry(entry);
      _loadEntries();
    }
  }

  void _openDetail(DiaryEntry entry) async {
    final result = await Navigator.pushNamed<dynamic>(
      context,
      AppRoutes.detail,
      arguments: entry,
    );
    if (result == 'deleted' || result == 'updated') _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAF7F2);

    return Scaffold(
      backgroundColor: bg,
      body: IndexedStack(
        index: _currentTab,
        children: [
          _HomeTab(
            entries: _entries,
            onDelete: _deleteEntry,
            onToggleFavorite: _toggleFavorite,
            onOpenDetail: _openDetail,
          ),
          const SearchScreen(),
          const SizedBox(),
          const FavoriteScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentTab,
        onTap: (i) async {
          if (i == 2) {
            final entry = await Navigator.pushNamed<DiaryEntry?>(
              context,
              AppRoutes.write,
            );
            if (entry != null) _addEntry(entry);
            return;
          }
          if (i == 4) {
            setState(() => _currentTab = 4);
            return;
          }
          setState(() => _currentTab = i);
        },
      ),
    );
  }
}

// ── Bottom Nav ──────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF242424) : Colors.white;
    const accent = Color(0xFFB5835A);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                current: currentIndex,
                accent: accent,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.search_rounded,
                label: 'Tìm kiếm',
                index: 1,
                current: currentIndex,
                accent: accent,
                onTap: onTap,
              ),
              // Nút viết ở giữa
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(2),
                  child: Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB5835A), Color(0xFF8B5E3C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB5835A).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.favorite_rounded,
                label: 'Yêu thích',
                index: 3,
                current: currentIndex,
                accent: accent,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Cá nhân',
                index: 4,
                current: currentIndex,
                accent: accent,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final Color accent;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = current == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? accent : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? accent : Colors.grey.shade400,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Home Tab ────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final List<DiaryEntry> entries;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onToggleFavorite;
  final Function(DiaryEntry) onOpenDetail;

  const _HomeTab({
    required this.entries,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Chào buổi sáng ☀️'
        : now.hour < 18
        ? 'Chào buổi chiều 🌤️'
        : 'Chào buổi tối 🌙';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2C2016), const Color(0xFF1A1A1A)]
                    : [const Color(0xFFF5EDE0), const Color(0xFFFAF7F2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFB5835A),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nhật ký của tôi',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF2C1810),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                // ── Row chip + nút quay video ──
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.book_rounded,
                      label: '${entries.length} bài viết',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      icon: Icons.favorite_rounded,
                      label:
                      '${entries.where((e) => e.isFavorite).length} yêu thích',
                      isDark: isDark,
                    ),
                    const Spacer(),
                    // ✅ NÚT QUAY VIDEO
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.video);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFB5835A), Color(0xFF8B5E3C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                              const Color(0xFFB5835A).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam_rounded,
                                size: 14, color: Colors.white),
                            SizedBox(width: 5),
                            Text(
                              'Quay video',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        entries.isEmpty
            ? SliverFillRemaining(child: _EmptyState())
            : SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _EntryCard(
                entry: entries[i],
                onDelete: onDelete,
                onToggleFavorite: onToggleFavorite,
                onOpenDetail: onOpenDetail,
              ),
              childCount: entries.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFB5835A).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFB5835A)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFB5835A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFB5835A).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              size: 48,
              color: Color(0xFFB5835A),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chưa có nhật ký nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB5835A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn ✏️ để bắt đầu viết\nnhật ký đầu tiên của bạn',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Entry Card ───────────────────────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  final DiaryEntry entry;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onToggleFavorite;
  final Function(DiaryEntry) onOpenDetail;

  const _EntryCard({
    required this.entry,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.onOpenDetail,
  });

  String _formatDate(DateTime d) {
    const months = [
      'Th1', 'Th2', 'Th3', 'Th4',  'Th5',  'Th6',
      'Th7', 'Th8', 'Th9', 'Th10', 'Th11', 'Th12'
    ];
    return '${d.day} ${months[d.month - 1]}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onOpenDetail(entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFB5835A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    entry.mood,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
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
                        ),
                        if (entry.isFavorite)
                          const Icon(
                            Icons.favorite_rounded,
                            size: 14,
                            color: Color(0xFFE57373),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(entry.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFFB5835A).withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (entry.content.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        entry.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.grey.shade500,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (val) {
                  if (val == 'delete') onDelete(entry.id);
                  if (val == 'favorite') onToggleFavorite(entry.id);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'favorite',
                    child: Row(children: [
                      Icon(
                        entry.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: const Color(0xFFE57373),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(entry.isFavorite ? 'Bỏ yêu thích' : 'Yêu thích'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Text('Xóa', style: TextStyle(color: Colors.red)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}