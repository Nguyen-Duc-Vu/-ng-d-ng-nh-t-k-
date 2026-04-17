import 'package:hive_flutter/hive_flutter.dart';
//Xử lý đăng nhập, đăng ký, đăng xuất người dùng
class AuthService {
  static const _boxName = 'users';
  static const _currentUserKey = 'currentUser';

  // Lấy box users
  static Box get _box => Hive.box(_boxName);

  // Đăng ký tài khoản mới
  static Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    // Kiểm tra email đã tồn tại chưa
    final users = _box.get('userList', defaultValue: <dynamic>[]) as List;
    final exists = users.any((u) =>
    (u as Map)['email'].toString().toLowerCase() ==
        email.toLowerCase());

    if (exists) return 'Email này đã được đăng ký!';

    // Lưu user mới vào danh sách
    final newUser = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'email': email.toLowerCase(),
      'password': password, // TODO: hash mật khẩu khi dùng thật
      'createdAt': DateTime.now().toIso8601String(),
    };

    users.add(newUser);
    await _box.put('userList', users);

    // Tự động đăng nhập sau khi đăng ký
    await _box.put(_currentUserKey, newUser);

    return null; // null = thành công
  }

  // Đăng nhập
  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    final users = _box.get('userList', defaultValue: <dynamic>[]) as List;

    final user = users.cast<Map>().firstWhere(
          (u) =>
      u['email'].toString().toLowerCase() == email.toLowerCase() &&
          u['password'] == password,
      orElse: () => {},
    );

    if (user.isEmpty) return 'Email hoặc mật khẩu không đúng!';

    // Lưu user hiện tại
    await _box.put(_currentUserKey, Map<String, dynamic>.from(user));
    return null; // null = thành công
  }

  // Đăng xuất
  static Future<void> logout() async {
    await _box.delete(_currentUserKey);
  }

  // Lấy thông tin user đang đăng nhập
  static Map<String, dynamic>? get currentUser {
    final raw = _box.get(_currentUserKey);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  // Kiểm tra đã đăng nhập chưa
  static bool get isLoggedIn => currentUser != null;

  // Cập nhật thông tin user
  static Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    final user = currentUser;
    if (user == null) return;

    user['name'] = name;
    user['email'] = email;
    await _box.put(_currentUserKey, user);

    // Cập nhật luôn trong danh sách users
    final users = _box.get('userList', defaultValue: <dynamic>[]) as List;
    final index =
    users.indexWhere((u) => (u as Map)['id'] == user['id']);
    if (index != -1) {
      users[index] = user;
      await _box.put('userList', users);
    }
  }

  // Đổi mật khẩu
  static Future<String?> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = currentUser;
    if (user == null) return 'Chưa đăng nhập!';
    if (user['password'] != oldPassword) return 'Mật khẩu cũ không đúng!';

    user['password'] = newPassword;
    await _box.put(_currentUserKey, user);

    final users = _box.get('userList', defaultValue: <dynamic>[]) as List;
    final index =
    users.indexWhere((u) => (u as Map)['id'] == user['id']);
    if (index != -1) {
      users[index] = user;
      await _box.put('userList', users);
    }
    return null;
  }
}