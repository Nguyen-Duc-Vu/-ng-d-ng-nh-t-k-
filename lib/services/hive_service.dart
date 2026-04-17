import 'package:hive_flutter/hive_flutter.dart';
import '../models/diary_entry.dart';
//Quản lý lưu trữ dữ liệu bằng Hive (thêm, sửa, xóa nhật ký)
class HiveService {
  static const String _boxName = 'diary_entries';
  static Box<DiaryEntry>? _box;

  /// Gọi 1 lần duy nhất trong main()
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(DiaryEntryAdapter());
    _box = await Hive.openBox<DiaryEntry>(_boxName);
  }

  static Box<DiaryEntry> get box {
    if (_box == null) throw Exception('HiveService chưa được khởi tạo!');
    return _box!;
  }

  // ── CRUD ──────────────────────────────────────────

  /// Thêm entry mới
  static Future<void> addEntry(DiaryEntry entry) async {
    await box.put(entry.id, entry);
  }

  /// Lấy tất cả entries, mới nhất lên đầu
  static List<DiaryEntry> getAllEntries() {
    final entries = box.values.toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  /// Cập nhật (toggle favorite, sửa nội dung…)
  static Future<void> updateEntry(DiaryEntry entry) async {
    await entry.save(); // HiveObject có sẵn .save()
  }

  /// Xóa theo id
  static Future<void> deleteEntry(String id) async {
    await box.delete(id);
  }

  /// Tìm kiếm theo title hoặc content
  static List<DiaryEntry> search(String query) {
    final q = query.toLowerCase();
    return box.values
        .where((e) =>
    e.title.toLowerCase().contains(q) ||
        e.content.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Chỉ lấy entries đã yêu thích
  static List<DiaryEntry> getFavorites() {
    return box.values.where((e) => e.isFavorite).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}