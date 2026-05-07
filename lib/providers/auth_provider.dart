import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  List<UserModel> _users = [];
  bool _loading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  static const _usersKey = 'users_data';
  static const _currentUserKey = 'current_user_id';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson != null) {
      final list = jsonDecode(usersJson) as List;
      _users = list.map((e) => UserModel.fromMap(e)).toList();
    } else {
      // Seed demo data
      _users = [
        UserModel(
          id: 'mgr001',
          name: 'Nguyễn Văn Hùng',
          email: 'manager@demo.com',
          phone: '0901234567',
          password: 'Manager@123',
          role: UserRole.manager,
        ),
        UserModel(
          id: 'usr001',
          name: 'Trần Thị Lan',
          email: 'user@demo.com',
          phone: '0987654321',
          password: 'User@123',
          role: UserRole.user,
        ),
      ];
      await _saveUsers();
    }

    // Removed auto-login logic so the app always starts at the login screen
    _currentUser = null;
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));

    if (email.isEmpty || password.isEmpty) {
      _error = 'Vui lòng nhập đầy đủ thông tin';
      _loading = false;
      notifyListeners();
      return _error;
    }

    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,}$').hasMatch(email)) {
      _error = 'Email không đúng định dạng';
      _loading = false;
      notifyListeners();
      return _error;
    }

    final user = _users.where((u) => u.email == email).firstOrNull;
    if (user == null) {
      _error = 'Email không tồn tại. Hãy đăng ký hoặc thử lại';
      _loading = false;
      notifyListeners();
      return _error;
    }

    if (user.password != password) {
      _error = 'Mật khẩu không đúng';
      _loading = false;
      notifyListeners();
      return _error;
    }

    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, user.id);
    _loading = false;
    notifyListeners();
    return null;
  }

  Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));

    if (name.trim().length < 2) {
      _error = 'Họ tên không hợp lệ';
      _loading = false;
      notifyListeners();
      return _error;
    }
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,}$').hasMatch(email)) {
      _error = 'Email không đúng định dạng';
      _loading = false;
      notifyListeners();
      return _error;
    }
    if (_users.any((u) => u.email == email)) {
      _error = 'Email đã được sử dụng. Hãy đăng nhập hoặc thử email khác';
      _loading = false;
      notifyListeners();
      return _error;
    }
    if (!RegExp(r'^(0[3|5|7|8|9])[0-9]{8}$').hasMatch(phone)) {
      _error = 'Số điện thoại không đúng chuẩn (VD: 09xxxxxxxx)';
      _loading = false;
      notifyListeners();
      return _error;
    }
    if (!RegExp(r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$%^&*]).{8,}$')
        .hasMatch(password)) {
      _error =
          'Mật khẩu phải ≥8 ký tự, có chữ hoa, số và ký tự đặc biệt (!@#\$...)';
      _loading = false;
      notifyListeners();
      return _error;
    }

    final newUser = UserModel(
      id: const Uuid().v4(),
      name: name.trim(),
      email: email,
      phone: phone,
      password: password,
      role: role,
    );
    _users.add(newUser);
    await _saveUsers();
    _currentUser = newUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, newUser.id);
    _loading = false;
    notifyListeners();
    return null;
  }

  Future<String?> forgotPassword(String email) async {
    _loading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));

    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,}$').hasMatch(email)) {
      _error = 'Email không đúng định dạng';
      _loading = false;
      notifyListeners();
      return _error;
    }
    final exists = _users.any((u) => u.email == email);
    if (!exists) {
      _error = 'Email không tồn tại trong hệ thống';
      _loading = false;
      notifyListeners();
      return _error;
    }
    _loading = false;
    notifyListeners();
    return null;
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? avatarPath,
  }) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      name: name,
      phone: phone,
      avatarPath: avatarPath,
    );
    final idx = _users.indexWhere((u) => u.id == _currentUser!.id);
    if (idx != -1) _users[idx] = _currentUser!;
    await _saveUsers();
    notifyListeners();
  }

  Future<String?> changePassword(String oldPass, String newPass) async {
    if (_currentUser == null) return 'Chưa đăng nhập';
    if (_currentUser!.password != oldPass) return 'Mật khẩu cũ không đúng';
    if (!RegExp(r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$%^&*]).{8,}$')
        .hasMatch(newPass)) {
      return 'Mật khẩu mới không đạt yêu cầu bảo mật';
    }
    _currentUser = _currentUser!.copyWith(password: newPass);
    final idx = _users.indexWhere((u) => u.id == _currentUser!.id);
    if (idx != -1) _users[idx] = _currentUser!;
    await _saveUsers();
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    notifyListeners();
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _usersKey, jsonEncode(_users.map((u) => u.toMap()).toList()));
  }

  // Expose user list for room provider (to get tenant names)
  UserModel? getUserById(String id) =>
      _users.where((u) => u.id == id).firstOrNull;

  List<UserModel> get allUsers => List.unmodifiable(_users);
}
