import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _loading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isOwner => _currentUser?.isOwner ?? false;

  // ── Khởi tạo: lắng nghe Firebase Auth state ─────────────────────────────
  Future<void> init() async {
    _currentUser = await AuthService.instance.currentUser;
    notifyListeners();

    // Lắng nghe thay đổi auth state (logout, token hết hạn...)
    AuthService.instance.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  // ── ĐĂNG NHẬP ────────────────────────────────────────────────────────────
  Future<String?> login(String email, String password) async {
    _setLoading(true);
    final result = await AuthService.instance.login(
      email: email,
      password: password,
    );
    _setLoading(false);

    if (result.isSuccess) {
      _currentUser = result.user;
      notifyListeners();
      return null;
    }
    return result.error;
  }

  // ── ĐĂNG KÝ ──────────────────────────────────────────────────────────────
  Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    _setLoading(true);
    final result = await AuthService.instance.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: role,
    );
    _setLoading(false);

    if (result.isSuccess) {
      _currentUser = result.user;
      notifyListeners();
      return null;
    }
    return result.error;
  }

  // ── ĐĂNG XUẤT ────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await AuthService.instance.logout();
    _currentUser = null;
    notifyListeners();
  }

  // ── QUÊN MẬT KHẨU ────────────────────────────────────────────────────────
  Future<String?> forgotPassword(String email) async {
    _setLoading(true);
    final result = await AuthService.instance.forgotPassword(email);
    _setLoading(false);
    return result.isSuccess ? null : result.error;
  }

  // ── ĐỔI MẬT KHẨU ─────────────────────────────────────────────────────────
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    final result = await AuthService.instance.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    _setLoading(false);
    return result.isSuccess ? null : result.error;
  }

  // ── CẬP NHẬT PROFILE ─────────────────────────────────────────────────────
  Future<String?> updateProfile({
    String? name,
    String? phone,
    String? avatar,
  }) async {
    if (_currentUser == null) return 'Chưa đăng nhập';
    _setLoading(true);
    final result = await AuthService.instance.updateProfile(
      uid: _currentUser!.uid,
      name: name,
      phone: phone,
      avatar: avatar,
    );
    _setLoading(false);

    if (result.isSuccess) {
      _currentUser = result.user;
      notifyListeners();
      return null;
    }
    return result.error;
  }

  void _setLoading(bool val) {
    _loading = val;
    notifyListeners();
  }
}
