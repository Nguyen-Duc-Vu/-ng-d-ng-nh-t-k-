import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/hive_service.dart';
import 'services/auth_service.dart';      // ✅ thêm import này
import 'services/notification_service.dart';
import 'providers/theme_provider.dart';
import 'routes/app_routes.dart';
//Điểm khởi chạy ứng dụng, khởi tạo Hive, theme và điều hướng
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();
  await Hive.openBox('users'); // ✅ đã có

  if (!kIsWeb) {
    await NotificationService.init();
  }

  final themeProvider = ThemeProvider();
  await themeProvider.init();

  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    // ✅ Kiểm tra đăng nhập — nếu đã đăng nhập thì vào Home
    // nếu chưa thì vào Login
    final startRoute = AuthService.isLoggedIn
        ? AppRoutes.home
        : AppRoutes.login;

    return MaterialApp(
      title: 'Nhật Ký',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB5835A),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB5835A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeProvider.themeMode,
      initialRoute: startRoute,           // ✅ sửa dòng này
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}