import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// Sealed result – tránh throw/catch lan tràn khắp nơi
class AuthResult {
  final UserModel? user;
  final String? error;
  bool get isSuccess => error == null;

  const AuthResult.success(this.user) : error = null;
  const AuthResult.failure(this.error) : user = null;
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // ── Stream trạng thái đăng nhập ──────────────────────────────────────────
  Stream<UserModel?> get authStateChanges => _auth.authStateChanges().asyncMap(
        (fbUser) async {
          if (fbUser == null) return null;
          try {
            return await _fetchUser(fbUser.uid);
          } catch (e) {
            print("Lỗi khi fetch user trong authStateChanges: $e");
            return null;
          }
        },
      );

  // ── Lấy user hiện tại (1 lần) ────────────────────────────────────────────
  Future<UserModel?> get currentUser async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return _fetchUser(fbUser.uid);
  }

  // ── ĐĂNG NHẬP ────────────────────────────────────────────────────────────
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = await _fetchUser(cred.user!.uid);
      if (user == null)
        return const AuthResult.failure('Không tìm thấy dữ liệu người dùng.');
      return AuthResult.success(user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.code));
    } catch (e) {
      return AuthResult.failure('Đã có lỗi xảy ra. Vui lòng thử lại.');
    }
  }

  // ── ĐĂNG KÝ ──────────────────────────────────────────────────────────────
  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    UserRole role = UserRole.user,
  }) async {
    // Validate phía client trước khi gọi Firebase
    final validErr = _validateRegister(name, email, phone, password);
    if (validErr != null) return AuthResult.failure(validErr);

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final newUser = UserModel(
        uid: cred.user!.uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: role,
      );

      // Lưu vào Firestore – dùng uid làm document ID (khớp ảnh của bạn)
      await _db.collection('users').doc(newUser.uid).set(newUser.toFirestore());
      // Nếu là owner → tạo service_configs mặc định
      if (role == UserRole.owner) {
        await _db.collection('service_configs').add({
          'owner_id': _db.doc('users/${newUser.uid}'), // reference giống ảnh
          'electricPrice': 0, // giá mặc định, owner tự chỉnh sau
          'waterPrice': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      // Cập nhật displayName trên Firebase Auth (tiện lợi về sau)
      await cred.user!.updateDisplayName(name.trim());

      return AuthResult.success(newUser);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.code));
    } catch (e) {
      return AuthResult.failure('Đăng ký thất bại. Vui lòng thử lại.');
    }
  }

  // ── ĐĂNG XUẤT ────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ── QUÊN MẬT KHẨU (gửi email reset) ─────────────────────────────────────
  Future<AuthResult> forgotPassword(String email) async {
    if (!_isValidEmail(email.trim())) {
      return const AuthResult.failure('Email không đúng định dạng.');
    }
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const AuthResult.success(null); // null user = chỉ gửi mail thôi
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.code));
    } catch (e) {
      return AuthResult.failure('Không thể gửi email. Vui lòng thử lại.');
    }
  }

  // ── ĐỔI MẬT KHẨU ─────────────────────────────────────────────────────────
  /// Yêu cầu re-authenticate trước (Firebase bắt buộc cho thao tác nhạy cảm).
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return const AuthResult.failure('Chưa đăng nhập.');

    final passErr = _validatePassword(newPassword);
    if (passErr != null) return AuthResult.failure(passErr);

    try {
      // Re-authenticate
      final cred = EmailAuthProvider.credential(
        email: fbUser.email!,
        password: currentPassword,
      );
      await fbUser.reauthenticateWithCredential(cred);

      // Đổi mật khẩu
      await fbUser.updatePassword(newPassword);
      return const AuthResult.success(null);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.code));
    } catch (e) {
      return AuthResult.failure('Đổi mật khẩu thất bại. Vui lòng thử lại.');
    }
  }

  // ── CẬP NHẬT PROFILE ─────────────────────────────────────────────────────
  Future<AuthResult> updateProfile({
    required String uid,
    String? name,
    String? phone,
    String? avatar,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name.trim();
      if (phone != null) updates['phone'] = phone.trim();
      if (avatar != null) updates['avatar'] = avatar;

      if (updates.isEmpty)
        return const AuthResult.failure('Không có gì thay đổi.');

      await _db.collection('users').doc(uid).update(updates);
      if (name != null) await _auth.currentUser?.updateDisplayName(name.trim());

      final updated = await _fetchUser(uid);
      return AuthResult.success(updated);
    } catch (e) {
      return AuthResult.failure('Cập nhật thất bại. Vui lòng thử lại.');
    }
  }

  // ── PRIVATE HELPERS ───────────────────────────────────────────────────────

  Future<UserModel?> _fetchUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromDoc(doc);
  }

  String? _validateRegister(
      String name, String email, String phone, String password) {
    if (name.trim().length < 2) return 'Họ tên phải có ít nhất 2 ký tự.';
    if (!_isValidEmail(email)) return 'Email không đúng định dạng.';
    if (!RegExp(r'^(0[3|5|7|8|9])[0-9]{8}$').hasMatch(phone)) {
      return 'Số điện thoại không hợp lệ (VD: 09xxxxxxxx).';
    }
    return _validatePassword(password);
  }

  String? _validatePassword(String password) {
    if (!RegExp(r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$%^&*]).{8,}$')
        .hasMatch(password)) {
      return 'Mật khẩu ≥8 ký tự, phải có chữ hoa, số và ký tự đặc biệt.';
    }
    return null;
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,}$').hasMatch(email);

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email không tồn tại trong hệ thống.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Mật khẩu không đúng.';
      case 'email-already-in-use':
        return 'Email đã được sử dụng. Hãy đăng nhập hoặc dùng email khác.';
      case 'invalid-email':
        return 'Email không đúng định dạng.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Hãy dùng mật khẩu mạnh hơn.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng thử lại sau.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Kiểm tra internet và thử lại.';
      case 'requires-recent-login':
        return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
      default:
        return 'Đã có lỗi xảy ra ($code).';
    }
  }
}
