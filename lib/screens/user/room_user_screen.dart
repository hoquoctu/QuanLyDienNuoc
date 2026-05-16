import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bh_room_provider.dart';
import '../../models/bh_room_model.dart';
import '../../models/boarding_house_model.dart';
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
  bool _cancelDialogShown = false;
  BhRoomProvider? _bhRoomProvider; // nullable — tránh LateInitializationError

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        _bhRoomProvider = context.read<BhRoomProvider>();
        _bhRoomProvider!.initForUser(user.uid);
        _bhRoomProvider!.addListener(_onProviderChanged);
      }
    });
  }

  void _onProviderChanged() {
    final provider = context.read<BhRoomProvider>();
    if (provider.wasCancelledByOwner && !_cancelDialogShown) {
      _cancelDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCancelledDialog();
      });
    } else if (!provider.wasCancelledByOwner) {
      _cancelDialogShown = false;
    }
  }


  @override
  void dispose() {
    _bhRoomProvider?.removeListener(_onProviderChanged);
    _codeCtrl.dispose();
    super.dispose();
  }

  // Hiện dialog thông báo chủ trọ đã hủy
  Future<void> _showCancelledDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 26),
            SizedBox(width: 8),
            Text('Yêu cầu bị hủy'),
          ],
        ),
        content: const Text(
          'Chủ trọ đã hủy yêu cầu tham gia phòng của bạn.\nBạn có thể liên hệ lại hoặc nhập mã phòng khác.',
          style: TextStyle(height: 1.6),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              context.read<BhRoomProvider>().clearCancelledFlag();
              Navigator.pop(ctx);
            },
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinRoom() async {
    // Kiểm tra code trống
    if (_codeCtrl.text.trim().isEmpty) {
      setState(() => _err = 'Vui lòng nhập mã phòng');
      return;
    }

    // Kiểm tra user null
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      setState(() => _err = 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại');
      return;
    }

    setState(() {
      _err = null;
      _joining = true;
    });

    final err = await context
        .read<BhRoomProvider>()
        .joinRoomByCode(_codeCtrl.text.trim(), user.uid, user.name);

    if (!mounted) return;
    setState(() {
      _joining = false;
      _err = err;
    });
    if (err == null) {
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
    final provider = context.watch<BhRoomProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Phòng trọ của tôi')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? _buildError(provider.error!)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: provider.room == null
                      ? _buildJoinRoom()
                      : provider.room!.bhRoomStatus == BhRoomStatus.waiting
                          ? _buildWaitingRoom(provider.room!, provider.boardingHouse)
                          : _buildRoomInfo(provider.room!, provider.boardingHouse),
                ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
            const SizedBox(height: 12),
            Text(msg, textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomInfo(BhRoomModel room, BoardingHouseModel? bh) {
    final statusColor = _statusColor(room.bhRoomStatus);
    final statusLabel = _statusLabel(room.bhRoomStatus);

    return Column(
      children: [
        // ── Room header card ─────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
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
              // Tên dãy trọ
              Text(
                bh?.bhName ?? 'Dãy trọ',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              // Số phòng
              Text(
                'Phòng ${room.bhRoomNumber}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              // Địa chỉ
              if (bh != null && bh.bhAddress.isNotEmpty)
                Text(
                  bh.bhAddress,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 12),
              // Badge trạng thái
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(room.bhRoomStatus),
                        color: statusColor, size: 14),
                    const SizedBox(width: 6),
                    Text(statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Thông tin nhà trọ ────────────────────────────────────────────
        if (bh != null) ...[
          _SectionCard(
            title: 'Thông tin dãy trọ',
            icon: Icons.apartment,
            children: [
              _InfoTile(
                icon: Icons.business,
                label: 'Tên dãy trọ',
                value: bh.bhName,
                color: AppTheme.primary,
              ),
              if (bh.bhAddress.isNotEmpty) ...[
                const Divider(height: 16),
                _InfoTile(
                  icon: Icons.location_on,
                  label: 'Địa chỉ',
                  value: bh.bhAddress,
                  color: Colors.orange,
                ),
              ],
              if (bh.bhDescription.isNotEmpty) ...[
                const Divider(height: 16),
                _InfoTile(
                  icon: Icons.description,
                  label: 'Mô tả',
                  value: bh.bhDescription,
                  color: Colors.teal,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
        ],

        // ── Chỉ số điện nước ─────────────────────────────────────────────
        _SectionCard(
          title: 'Chỉ số hiện tại',
          icon: Icons.speed,
          children: [
            _InfoTile(
              icon: Icons.bolt,
              label: 'Chỉ số điện',
              value: '${room.bhRoomLastElec.toStringAsFixed(1)} kWh',
              color: AppTheme.elecColor,
            ),
            const Divider(height: 16),
            _InfoTile(
              icon: Icons.water_drop,
              label: 'Chỉ số nước',
              value: '${room.bhRoomLastWater.toStringAsFixed(1)} m³',
              color: AppTheme.waterColor,
            ),
            if (room.bhRoomUpdateTime != null) ...[
              const Divider(height: 16),
              _InfoTile(
                icon: Icons.update,
                label: 'Cập nhật lần cuối',
                value:
                    '${room.bhRoomUpdateTime!.day}/${room.bhRoomUpdateTime!.month}/${room.bhRoomUpdateTime!.year}',
                color: AppTheme.textSecondary,
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // ── Thông tin thuê phòng ─────────────────────────────────────────
        _SectionCard(
          title: 'Thông tin thuê phòng',
          icon: Icons.person,
          children: [
            _InfoTile(
              icon: Icons.person_outline,
              label: 'Người thuê',
              value: room.bhRoomTenantName ?? '—',
              color: AppTheme.primary,
            ),
            if (room.bhRoomTimeStart != null) ...[
              const Divider(height: 16),
              _InfoTile(
                icon: Icons.calendar_month_outlined,
                label: 'Bắt đầu thuê',
                value:
                    '${room.bhRoomTimeStart!.day}/${room.bhRoomTimeStart!.month}/${room.bhRoomTimeStart!.year}',
                color: AppTheme.primary,
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.home_outlined,
                    size: 52, color: AppTheme.primary),
              ),
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
            hintText: 'Nhập mã 6 ký tự do chủ trọ cấp',
            errorText: _err,
            prefixIcon:
                const Icon(Icons.qr_code_scanner, color: AppTheme.primary),
          ),
          onChanged: (_) => setState(() => _err = null),
        ),
        const SizedBox(height: 16),
        _joining
            ? const CircularProgressIndicator()
            : SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _joinRoom,
                  icon: const Icon(Icons.send),
                  label: const Text('Gửi yêu cầu tham gia'),
                ),
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

  // ── Màn hình chờ xác nhận (status = waiting) ──────────────────────────────
  Widget _buildWaitingRoom(BhRoomModel room, BoardingHouseModel? bh) {
    return Column(
      children: [
        // Hero banner màu amber
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded,
                    color: Colors.white, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'CHỜ XÁC NHẬN',
                style: TextStyle(
                    color: Colors.white70, fontSize: 12, letterSpacing: 1.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Phòng ${room.bhRoomNumber}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900),
              ),
              if (bh != null) ...[
                const SizedBox(height: 4),
                Text(bh.bhName,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
                if (bh.bhAddress.isNotEmpty)
                  Text(bh.bhAddress,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12),
                      textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Thông báo chờ
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Column(
            children: [
              Icon(Icons.mark_email_unread_outlined,
                  color: Color(0xFFF59E0B), size: 36),
              SizedBox(height: 12),
              Text(
                'Yêu cầu đã được gửi!',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppTheme.textPrimary),
              ),
              SizedBox(height: 8),
              Text(
                'Chủ trọ đang xét duyệt yêu cầu của bạn.\nVui lòng chờ thông báo xác nhận.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Thông tin yêu cầu
        _SectionCard(
          title: 'Thông tin yêu cầu',
          icon: Icons.info_outline,
          children: [
            _InfoTile(
              icon: Icons.person_outline,
              label: 'Họ tên',
              value: room.bhRoomTenantName ?? '—',
              color: AppTheme.primary,
            ),
            if (room.bhRoomUpdateTime != null) ...[
              const Divider(height: 16),
              _InfoTile(
                icon: Icons.access_time,
                label: 'Thời gian gửi',
                value:
                    '${room.bhRoomUpdateTime!.day}/${room.bhRoomUpdateTime!.month}/${room.bhRoomUpdateTime!.year} '
                    '${room.bhRoomUpdateTime!.hour.toString().padLeft(2, '0')}:${room.bhRoomUpdateTime!.minute.toString().padLeft(2, '0')}',
                color: Colors.teal,
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  Color _statusColor(BhRoomStatus s) {
    switch (s) {
      case BhRoomStatus.occupied:
        return AppTheme.successColor;
      case BhRoomStatus.waiting:
        return const Color(0xFFF59E0B);
      case BhRoomStatus.pending:
        return Colors.deepPurple;
      case BhRoomStatus.inactive:
        return AppTheme.textHint;
      case BhRoomStatus.empty:
        return AppTheme.primary;
    }
  }

  String _statusLabel(BhRoomStatus s) {
    switch (s) {
      case BhRoomStatus.occupied:
        return 'Đang thuê';
      case BhRoomStatus.waiting:
        return 'Chờ xác nhận';
      case BhRoomStatus.pending:
        return 'Pending';
      case BhRoomStatus.inactive:
        return 'Ngưng hoạt động';
      case BhRoomStatus.empty:
        return 'Phòng trống';
    }
  }

  IconData _statusIcon(BhRoomStatus s) {
    switch (s) {
      case BhRoomStatus.occupied:
        return Icons.check_circle;
      case BhRoomStatus.waiting:
        return Icons.hourglass_top_rounded;
      case BhRoomStatus.pending:
        return Icons.pending;
      case BhRoomStatus.inactive:
        return Icons.block;
      case BhRoomStatus.empty:
        return Icons.home_outlined;
    }
  }
}

// ── Section Card ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

// ── Info Tile ─────────────────────────────────────────────────────────────────
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
