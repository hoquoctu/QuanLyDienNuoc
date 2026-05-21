import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/screens/owner/invoice/PaymentListScreen.dart';
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

    final config = await ServiceConfigService.getPrices(
      ownerUid,
    );

    _elecCtrl.text = (config['electricPrice'] ?? 3500).toInt().toString();

    _waterCtrl.text = (config['waterPrice'] ?? 15000).toInt().toString();

    setState(() {
      _loading = false;
    });
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
          ? const Center(
              child: CircularProgressIndicator(),
            )
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
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            user.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
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
