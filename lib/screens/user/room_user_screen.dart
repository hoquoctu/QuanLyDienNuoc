import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/room_block_provider.dart';
import '../../models/room_model.dart';
import '../../theme/app_theme.dart';

class RoomUserScreen extends StatefulWidget {
  const RoomUserScreen({super.key});
  @override
  State<RoomUserScreen> createState() => _RoomUserScreenState();
}

class _RoomUserScreenState extends State<RoomUserScreen> {
  final _codeCtrl = TextEditingController();
  String? _err;
  bool _joining = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    setState(() {
      _err = null;
      _joining = true;
    });
    final user = context.read<AuthProvider>().currentUser!;
    final err = await context
        .read<RoomProvider>()
        .requestJoinRoom(_codeCtrl.text.trim(), user.uid, user.name);
    setState(() {
      _joining = false;
      _err = err;
    });
    if (err == null && mounted) {
      _codeCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã gửi yêu cầu! Chờ chủ trọ xác nhận.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser!;
    final room = context.watch<RoomProvider>().roomForTenant(user.uid);
    final block = room != null
        ? context.read<RoomBlockProvider>().getById(room.blockId)
        : null;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Phòng trọ của tôi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: room != null ? _buildRoomInfo(room, block) : _buildJoinRoom(),
      ),
    );
  }

  Widget _buildRoomInfo(RoomModel room, block) {
    return Column(
      children: [
        // Room header card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryDark],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.home, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                block?.name ?? 'Dãy trọ',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                'Phòng ${room.name}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900),
              ),
              if (block != null)
                Text(
                  block.address,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Status
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _InfoTile(
                icon: Icons.bolt,
                label: 'Chỉ số điện hiện tại',
                value: '${room.lastElecReading.toInt()} kWh',
                color: AppTheme.elecColor,
              ),
              const Divider(height: 16),
              _InfoTile(
                icon: Icons.water_drop,
                label: 'Chỉ số nước hiện tại',
                value: '${room.lastWaterReading.toInt()} m³',
                color: AppTheme.waterColor,
              ),
              if (room.tenantSince != null) ...[
                const Divider(height: 16),
                _InfoTile(
                  icon: Icons.calendar_month_outlined,
                  label: 'Thuê từ ngày',
                  value:
                      '${room.tenantSince!.day}/${room.tenantSince!.month}/${room.tenantSince!.year}',
                  color: AppTheme.primary,
                ),
              ],
            ],
          ),
        ),

        if (room.status == RoomStatus.pending) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
            ),
            child: Row(children: const [
              Icon(Icons.hourglass_empty, color: AppTheme.primary, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Yêu cầu của bạn đang chờ chủ trọ xác nhận...',
                  style: TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _buildJoinRoom() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(Icons.home_outlined,
                  size: 64, color: AppTheme.textHint),
              const SizedBox(height: 16),
              const Text(
                'Chưa có phòng trọ',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nhập mã phòng do chủ trọ cung cấp để tham gia',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _codeCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Mã phòng trọ',
            hintText: 'VD: B101ABC123456',
            errorText: _err,
            prefixIcon:
                const Icon(Icons.qr_code_scanner, color: AppTheme.primary),
          ),
          onChanged: (_) => setState(() => _err = null),
        ),
        const SizedBox(height: 16),
        _joining
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                onPressed: _joinRoom,
                icon: const Icon(Icons.send),
                label: const Text('Gửi yêu cầu tham gia'),
              ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.warningColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: const [
              Icon(Icons.info_outline, color: AppTheme.warningColor, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mã phòng có hiệu lực trong 30 phút kể từ khi chủ trọ tạo. Hãy liên hệ chủ trọ để lấy mã.',
                  style: TextStyle(fontSize: 12, color: AppTheme.warningColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }
}
