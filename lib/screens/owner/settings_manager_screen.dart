import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/screens/owner/invoice/PaymentListScreen.dart';
import 'package:quanlydiennc_app/services/CloudinaryUpload.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_sheet_confirm.dart';
import '../../services/service_config_service.dart';

class SettingsManagerScreen extends StatefulWidget {
  const SettingsManagerScreen({super.key});
  @override
  State<SettingsManagerScreen> createState() => _SettingsManagerScreenState();
}

class _SettingsManagerScreenState extends State<SettingsManagerScreen> {
  late TextEditingController _elecCtrl;
  late TextEditingController _waterCtrl;
  bool _loading = true;
  bool _uploadingAvatar = false; // ← thêm

  @override
  void initState() {
    super.initState();
    _elecCtrl = TextEditingController();
    _waterCtrl = TextEditingController();
    _loadConfig();
  }

  @override
  void dispose() {
    _elecCtrl.dispose();
    _waterCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final ownerUid = context.read<AuthProvider>().currentUser!.uid;
    final config = await ServiceConfigService.getPrices(ownerUid);
    _elecCtrl.text = (config['electricPrice'] ?? 3500).toInt().toString();
    _waterCtrl.text = (config['waterPrice'] ?? 15000).toInt().toString();
    setState(() => _loading = false);
  }

//edit profile
  Future<void> _editProfileDialog() async {
    final user = context.read<AuthProvider>().currentUser!;
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cập nhật thông tin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Họ và tên'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final error = await context.read<AuthProvider>().updateProfile(
            name: nameCtrl.text.trim(),
            phone: phoneCtrl.text.trim(),
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Cập nhật thông tin thành công'),
          backgroundColor:
              error == null ? AppTheme.successColor : AppTheme.errorColor,
        ),
      );

      setState(() {}); // refresh UI hiển thị tên/sđt mới
    }
  }

  // ── PICK & UPLOAD AVATAR ─────────────────────────────────────────────
  Future<void> _pickAndUploadAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file == null || !mounted) return;

    setState(() => _uploadingAvatar = true);

    try {
      final url = await uploadToCloudinaryOnForlder(
        File(file.path),
        folder: 'Room_Zy/avatar',
      );

      if (url == null) throw Exception('Upload thất bại');

      final error =
          await context.read<AuthProvider>().updateProfile(avatar: url);

      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppTheme.errorColor),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật ảnh đại diện thành công'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _savePrices() async {
    final elec = double.tryParse(_elecCtrl.text);
    final water = double.tryParse(_waterCtrl.text);
    if (elec == null || water == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Giá không hợp lệ')));
      return;
    }

    final ok = await showConfirmSheet<bool>(
      context,
      title: 'Cập nhật giá điện nước',
      subtitle:
          'Giá mới sẽ áp dụng cho tất cả hóa đơn tạo từ bây giờ và thông báo đến toàn bộ cư dân.',
      confirmLabel: 'Cập nhật & Thông báo',
    );
    if (ok == true && mounted) {
      final ownerUid = context.read<AuthProvider>().currentUser!.uid;

      final result = await ServiceConfigService.updatePrices(
        ownerId: ownerUid,
        electricPrice: elec,
        waterPrice: water,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result ?? '✅ Đã cập nhật giá thành công',
          ),
          backgroundColor:
              result == null ? AppTheme.successColor : AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser!;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Cài đặt')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Manager profile
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        // Avatar có nút chỉnh sửa
                        GestureDetector(
                          onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                backgroundImage: user.avatar != null
                                    ? NetworkImage(user.avatar!)
                                    : null,
                                child: user.avatar == null
                                    ? Text(
                                        user.name.substring(0, 1).toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      )
                                    : null,
                              ),
                              // Loading overlay
                              if (_uploadingAvatar)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              // Camera icon badge
                              if (!_uploadingAvatar)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      size: 14,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: _editProfileDialog,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(user.name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.edit,
                                        size: 14, color: Colors.white70),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(user.email,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                                Text(user.phone,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('Chủ trọ',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Price settings
                  const Text(
                    '⚡ Điều chỉnh giá điện nước',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cập nhật giá sẽ gửi thông báo tự động đến tất cả cư dân',
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  _PriceField(
                    label: 'Giá điện (đ/kWh)',
                    icon: Icons.bolt,
                    color: AppTheme.elecColor,
                    controller: _elecCtrl,
                  ),
                  const SizedBox(height: 12),
                  _PriceField(
                    label: 'Giá nước (đ/m³)',
                    icon: Icons.water_drop,
                    color: AppTheme.waterColor,
                    controller: _waterCtrl,
                  ),

                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.campaign_outlined,
                            color: AppTheme.warningColor, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sau khi lưu, thông báo giá mới sẽ được gửi tới tất cả cư dân kèm % thay đổi.',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.warningColor),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _savePrices,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Lưu & Thông báo cư dân'),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PaymentListScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Lịch sử thanh toán'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Logout
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await showConfirmSheet<bool>(
                        context,
                        title: 'Đăng xuất',
                        subtitle: 'Bạn có chắc muốn đăng xuất?',
                        confirmLabel: 'Đăng xuất',
                        confirmColor: AppTheme.errorColor,
                      );
                      if (ok == true && context.mounted) {
                        await context.read<AuthProvider>().logout();
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Đăng xuất'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PriceField extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final TextEditingController controller;
  const _PriceField({
    required this.label,
    required this.icon,
    required this.color,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: label,
                suffix: const Text('đ',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
              ),
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 18, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
