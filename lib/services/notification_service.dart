import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/diary_entry.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // ID cố định cho từng loại notification
  static const _idDailyReminder = 0;
  static const _idOnThisDay     = 1;

  // Key lưu ngày đã show "Ký ức hôm nay" — tránh spam
  static const _prefKeyLastShown = 'on_this_day_last_shown';

  // ── Init ─────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (kIsWeb) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: iOS),
    );
  }

  // ── Nhắc viết nhật ký hàng ngày ──────────────────────────────────────────

  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;

    await _plugin.cancel(_idDailyReminder);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _idDailyReminder,
      '📔 Nhật ký hôm nay',
      'Đừng quên ghi lại những khoảnh khắc của ngày hôm nay nhé!',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Nhắc nhở viết nhật ký',
          channelDescription: 'Nhắc nhở hàng ngày để viết nhật ký',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ── Nhắc "Ký ức hôm nay" ─────────────────────────────────────────────────
  //
  // Gọi mỗi khi mở app. Logic:
  //   1. Kiểm tra đã show hôm nay chưa (SharedPreferences) → bỏ qua nếu rồi
  //   2. Tìm entry cùng ngày/tháng năm ngoái hoặc 1 tháng trước
  //   3. Nếu có → schedule notification vào 8:00 sáng hôm nay (hoặc ngay nếu đã qua 8h)
  //   4. Lưu ngày đã show để tránh spam
  //
  static Future<void> scheduleOnThisDay(List<DiaryEntry> entries) async {
    if (kIsWeb) return;

    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';

    // ✅ Anti-spam: chỉ show 1 lần mỗi ngày
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString(_prefKeyLastShown);
    if (lastShown == todayKey) return;

    // Tìm entry ký ức
    DiaryEntry? memory;
    String memoryLabel = '';

    for (final e in entries) {
      final diffYears = now.year - e.date.year;
      final sameMonth = e.date.month == now.month;
      final sameDay   = e.date.day == now.day;

      if (diffYears >= 1 && sameMonth && sameDay) {
        // Ưu tiên entry gần nhất (nhỏ nhất diffYears)
        if (memory == null || diffYears < (now.year - memory.date.year)) {
          memory = e;
          memoryLabel = diffYears == 1 ? '1 năm trước' : '$diffYears năm trước';
        }
      } else if (diffYears == 0 &&
          now.month - e.date.month == 1 &&
          sameDay &&
          memory == null) {
        memory = e;
        memoryLabel = '1 tháng trước';
      }
    }

    if (memory == null) {
      await _plugin.cancel(_idOnThisDay);
      return;
    }

    // ✅ Nội dung đầy đủ hơn
    final excerpt = memory.content.isNotEmpty
        ? (memory.content.length > 80
        ? '${memory.content.substring(0, 80)}...'
        : memory.content)
        : 'Bạn đã ghi lại khoảnh khắc này $memoryLabel.';

    final bigBody = '${memory.mood}  ${memory.title}\n\n"$excerpt"';

    // ✅ Schedule vào 8:00 sáng hôm nay (hoặc ngay nếu đã qua 8h)
    final morning8 = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, 8, 0);
    final fireTime = morning8.isBefore(tz.TZDateTime.now(tz.local))
        ? tz.TZDateTime.now(tz.local).add(const Duration(seconds: 3))
        : morning8;

    await _plugin.zonedSchedule(
      _idOnThisDay,
      '🕰️ Ký ức $memoryLabel',
      '${memory.mood} ${memory.title}',
      fireTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'on_this_day',
          'Ký ức hôm nay',
          channelDescription: 'Nhắc nhở về nhật ký trong quá khứ',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(
            bigBody,
            contentTitle: '🕰️ Ký ức $memoryLabel',
            summaryText: 'Nhật ký của bạn',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
          subtitle: 'Ngày này trong quá khứ...',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );

    // ✅ Lưu ngày đã show
    await prefs.setString(_prefKeyLastShown, todayKey);
  }

  // ── Huỷ tất cả ───────────────────────────────────────────────────────────

  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  // ── Reset để test (dùng khi dev) ─────────────────────────────────────────

  static Future<void> resetOnThisDayForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyLastShown);
  }
}