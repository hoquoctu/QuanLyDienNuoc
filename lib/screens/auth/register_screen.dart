import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/screens/owner/home_manager_screen.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../user/home_user_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  UserRole _selectedRole = UserRole.user;
  String? _err;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _err = null);
    final auth = context.read<AuthProvider>();
    final err = await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      password: _passCtrl.text,
      role: _selectedRole,
    );

    if (!mounted) return;

    if (err != null) {
      setState(() => _err = err);
      if (err.contains('Mật khẩu') || err.contains('mật khẩu')) {
        _passCtrl.clear();
      }
      if (err.contains('điện thoại')) _phoneCtrl.clear();
      return;
    }

    // Điều hướng theo role sau khi đăng ký thành công
    final user = auth.currentUser!;
    final destination = user.role == UserRole.owner
        ? const HomeManagerScreen()
        : const HomeUserScreen();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo tài khoản mới'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      backgroundColor: AppTheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role selector
            const Text(
              'Vai trò',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _RoleTile(
                    label: 'Người thuê',
                    icon: Icons.person_outline,
                    selected: _selectedRole == UserRole.user,
                    onTap: () => setState(() => _selectedRole = UserRole.user),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RoleTile(
                    label: 'Chủ trọ',
                    icon: Icons.home_work_outlined,
                    selected: _selectedRole == UserRole.owner,
                    onTap: () => setState(() => _selectedRole = UserRole.owner),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            CustomTextField(
              label: 'Họ và tên',
              hint: 'Nguyễn Văn A',
              controller: _nameCtrl,
              prefixIcon: const Icon(Icons.person_outline,
                  color: AppTheme.textHint, size: 20),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Email',
              hint: 'example@gmail.com',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined,
                  color: AppTheme.textHint, size: 20),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Số điện thoại',
              hint: '09xxxxxxxx',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_outlined,
                  color: AppTheme.textHint, size: 20),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Mật khẩu',
              hint: 'Tối thiểu 8 ký tự, chữ hoa, số, ký tự đặc biệt',
              controller: _passCtrl,
              isPassword: true,
              prefixIcon: const Icon(Icons.lock_outline,
                  color: AppTheme.textHint, size: 20),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '🔒 Mật khẩu phải có ≥8 ký tự, 1 chữ hoa, 1 số và 1 ký tự đặc biệt (!@#\$...)',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),

            if (_err != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.errorColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_err!,
                          style: const TextStyle(
                              color: AppTheme.errorColor, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),
            auth.loading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _register,
                      child: const Text('Đăng ký'),
                    ),
                  ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Đã có tài khoản? Đăng nhập',
                  style: TextStyle(color: AppTheme.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _RoleTile(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.1)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? AppTheme.primary : AppTheme.textHint,
                size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
