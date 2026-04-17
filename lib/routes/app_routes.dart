import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/write_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/search_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/register_screen.dart';
import '../screens/login_screen.dart';    // ✅ thêm import
import '../screens/video_screen.dart';
import '../screens/edit_screen.dart';

import '../models/diary_entry.dart';

class AppRoutes {
  static const String home     = '/';
  static const String write    = '/write';
  static const String detail   = '/detail';
  static const String search   = '/search';
  static const String profile  = '/profile';
  static const String login    = '/login';    // ✅ thêm
  static const String register = '/register';
  static const String video    = '/video';
  static const String edit     = '/edit';

  static Map<String, WidgetBuilder> get routes => {
    home:     (_) => const HomeScreen(),
    search:   (_) => const SearchScreen(),
    profile:  (_) => const ProfileScreen(),
    login:    (_) => const LoginScreen(),    // ✅ thêm
    register: (_) => const RegisterScreen(),
    video:    (_) => const VideoScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {

      case write:
        return MaterialPageRoute<DiaryEntry?>(
          builder: (_) => const WriteScreen(),
          settings: settings,
        );

      case detail:
        final entry = settings.arguments as DiaryEntry;
        return MaterialPageRoute<dynamic>(
          builder: (_) => DetailScreen(entry: entry),
          settings: settings,
        );

      case edit:
        final entry = settings.arguments as DiaryEntry;
        return MaterialPageRoute<String>(
          builder: (_) => EditScreen(entry: entry),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('404 — Không tìm thấy trang')),
          ),
        );
    }
  }
}