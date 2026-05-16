import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bh_room_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_sheet_confirm.dart';
import '../../widgets/custom_text_field.dart';

class SettingsUserScreen extends StatefulWidget {
  const SettingsUserScreen({super.key});
  @override
  State<SettingsUserScreen> createState() => _SettingsUserScreenState();
}

class _SettingsUserScreenState extends State<SettingsUserScreen> {
  bool _editMode = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser!;
    _nameCtrl = TextEditingController(text: user.name);
    _phoneCtrl = TextEditingController(text: user.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile != null && mounted) {
      await context.read<AuthProvider>().updateProfile(avatar: xfile.path);
    }
  }

  Future<void> _saveProfile() async {
    await context.read<AuthProvider>().updateProfile(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );
    setState(() => _editMode = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu thông tin!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Cài đặt'),
        actions: [
          if (!_editMode)
            TextButton(
              onPressed: () => setState(() => _editMode = true),
              child: const Text('Chỉnh sửa',
                  style: TextStyle(color: AppTheme.primary)),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Lưu',
                  style: TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            Center(
              child: GestureDetector(
                onTap: _editMode ? _pickAvatar : null,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppTheme.primary.withOpacity(0.15),
                      child: Text(
                        user.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 40,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (_editMode)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 16),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (!_editMode) ...[
              Text(user.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: AppTheme.textPrimary)),
              Text(user.role.name == 'user' ? 'Người thuê' : 'Chủ trọ',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
            ],
            const SizedBox(height: 24),

            // Info fields
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  if (_editMode) ...[
                    CustomTextField(
                      label: 'Họ và tên',
                      controller: _nameCtrl,
                      prefixIcon: const Icon(Icons.person_outline,
                          color: AppTheme.textHint, size: 20),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Số điện thoại',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined,
                          color: AppTheme.textHint, size: 20),
                    ),
                  ] else ...[
                    _InfoRow(
                        icon: Icons.person_outline,
                        label: 'Họ tên',
                        value: user.name),
                    const Divider(height: 16),
                    _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user.email),
                    const Divider(height: 16),
                    _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Điện thoại',
                        value: user.phone),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Change password button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lock_outline,
                      color: AppTheme.primary, size: 20),
                ),
                title: const Text('Đổi mật khẩu',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                trailing:
                    const Icon(Icons.chevron_right, color: AppTheme.textHint),
                onTap: () => _showChangePasswordSheet(context),
              ),
            ),

            const SizedBox(height: 12),

            // Logout
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.logout,
                      color: AppTheme.errorColor, size: 20),
                ),
                title: const Text('Đăng xuất',
                    style: TextStyle(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w600)),
                onTap: () async {
                  final ok = await showConfirmSheet<bool>(
                    context,
                    title: 'Đăng xuất',
                    subtitle: 'Bạn có chắc muốn đăng xuất?',
                    confirmLabel: 'Đăng xuất',
                    confirmColor: AppTheme.errorColor,
                  );
                  if (ok == true && context.mounted) {
                    // Reset dữ liệu phòng trước khi logout
                    context.read<BhRoomProvider>().reset();
                    await context.read<AuthProvider>().logout();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    String? err;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Đổi mật khẩu',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Mật khẩu cũ',
                  controller: oldCtrl,
                  isPassword: true,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Mật khẩu mới',
                  controller: newCtrl,
                  isPassword: true,
                ),
                if (err != null) ...[
                  const SizedBox(height: 8),
                  Text(err!,
                      style: const TextStyle(
                          color: AppTheme.errorColor, fontSize: 12)),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final e = await context.read<AuthProvider>().changePassword(
                          currentPassword: oldCtrl.text,
                          newPassword: newCtrl.text,
                        );
                    if (e != null) {
                      setSheetState(() => err = e);
                    } else if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đổi mật khẩu thành công!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  },
                  child: const Text('Xác nhận đổi mật khẩu'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textHint),
        const SizedBox(width: 10),
        Text(label,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
