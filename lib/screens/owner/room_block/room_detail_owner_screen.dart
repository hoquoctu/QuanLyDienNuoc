import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/models/bh_room_model.dart';
import 'package:quanlydiennc_app/models/notification_model.dart';
import 'package:quanlydiennc_app/providers/auth_provider.dart';
import 'package:quanlydiennc_app/providers/owner/boarding_house_provider.dart';
import 'package:quanlydiennc_app/providers/owner/room_review_provider.dart';
import 'package:quanlydiennc_app/services/manager/notification_service.dart';
import 'package:quanlydiennc_app/services/manager/unlink_request_service.dart';
import 'package:quanlydiennc_app/theme/app_theme.dart';
import 'package:quanlydiennc_app/widgets/bottom_sheet_confirm.dart';
import 'package:quanlydiennc_app/widgets/room_review_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ROOM DETAIL OWNER SCREEN
// Tab 0: Thông tin phòng
// Tab 1: Quản lý (actions theo trạng thái)
// Tab 2: Đánh giá (chỉ xem)
// ═══════════════════════════════════════════════════════════════════════════

class RoomDetailOwnerScreen extends StatefulWidget {
  final BhRoomModel room;
  final String bhName;
  final String ownerId;
  final String ownerName;

  const RoomDetailOwnerScreen({
    super.key,
    required this.room,
    required this.bhName,
    required this.ownerId,
    required this.ownerName,
  });

  @override
  State<RoomDetailOwnerScreen> createState() => _RoomDetailOwnerScreenState();
}

class _RoomDetailOwnerScreenState extends State<RoomDetailOwnerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomReviewProvider>().init(widget.room.bhRoomId);
      // Khởi động timer nếu phòng đã có code từ trước
      _syncTimer();
    });
  }

  // Lấy room mới nhất từ provider (không watch, chỉ read)
  BhRoomModel get _liveRoom =>
      context.read<BoardingHouseProvider>().getRoomById(widget.room.bhRoomId) ??
      widget.room;

  /// Đồng bộ timer với expiry hiện tại của room.
  /// Gọi mỗi khi build() phát hiện code thay đổi.
  void _syncTimer() {
    final expiry = _liveRoom.bhRoomCodeExpiry;
    if (expiry == null) {
      _timer?.cancel();
      if (_remaining != Duration.zero)
        setState(() => _remaining = Duration.zero);
      return;
    }
    final diff = expiry.difference(DateTime.now());
    if (diff.isNegative) {
      _timer?.cancel();
      if (_remaining != Duration.zero)
        setState(() => _remaining = Duration.zero);
      context.read<BoardingHouseProvider>().resetRoomCode(widget.room.bhRoomId);
      return;
    }
    // Timer chưa chạy hoặc expiry mới → restart
    _timer?.cancel();
    setState(() => _remaining = diff);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final d = _liveRoom.bhRoomCodeExpiry?.difference(DateTime.now()) ??
          Duration.zero;
      if (d.isNegative || d == Duration.zero) {
        _timer?.cancel();
        setState(() => _remaining = Duration.zero);
        context
            .read<BoardingHouseProvider>()
            .resetRoomCode(widget.room.bhRoomId);
      } else {
        setState(() => _remaining = d);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = context.watch<RoomReviewProvider>();

    // watch provider → tự rebuild khi Firestore stream push data mới
    final bhProvider = context.watch<BoardingHouseProvider>();
    final room = bhProvider.getRoomById(widget.room.bhRoomId) ?? widget.room;

    // Nếu code thay đổi (vừa generate hoặc vừa expire) → sync timer
    final newExpiry = room.bhRoomCodeExpiry;
    final timerExpiry =
        _remaining > Duration.zero ? DateTime.now().add(_remaining) : null;
    if (newExpiry != timerExpiry) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncTimer());
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phòng ${room.bhRoomNumber}'),
            Text(
              widget.bhName,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            const Tab(text: 'Thông tin'),
            const Tab(text: 'Quản lý'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Đánh giá'),
                  if (reviewProvider.reviews.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${reviewProvider.reviews.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _RoomInfoTab(room: room),
          _ManageTab(
            room: room,
            remaining: _remaining,
            bhName: widget.bhName,
            ownerId: widget.ownerId,
            ownerName: widget.ownerName,
          ),
          _ReviewsTab(provider: reviewProvider),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 0 — Thông tin phòng
// ═══════════════════════════════════════════════════════════════════════════

class _RoomInfoTab extends StatelessWidget {
  final BhRoomModel room;
  const _RoomInfoTab({required this.room});

  @override
  Widget build(BuildContext context) {
    final isOccupied = room.bhRoomStatus == BhRoomStatus.occupied;
    final isWaiting = room.bhRoomStatus == BhRoomStatus.waiting;
    final isAvailable = room.bhRoomStatus == BhRoomStatus.available;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (isOccupied) {
      statusColor = AppTheme.successColor;
      statusLabel = 'Đang thuê';
      statusIcon = Icons.check_circle_outline;
    } else if (isWaiting) {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = 'Chờ xác nhận';
      statusIcon = Icons.hourglass_top_rounded;
    } else if (isAvailable) {
      statusColor = AppTheme.primary;
      statusLabel = 'Trống';
      statusIcon = Icons.door_front_door_outlined;
    } else {
      statusColor = AppTheme.textSecondary;
      statusLabel = 'Không hoạt động';
      statusIcon = Icons.block_outlined;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCard(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trạng thái',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (room.bhRoomTenantName != null) ...[
            _InfoCard(
              label: 'Người thuê hiện tại',
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Text(
                        room.bhRoomTenantName!.isNotEmpty
                            ? room.bhRoomTenantName![0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      room.bhRoomTenantName!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          _InfoCard(
            label: 'Chỉ số điện nước',
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      icon: Icons.bolt,
                      iconColor: AppTheme.elecColor,
                      label: 'Điện',
                      value: '${room.bhRoomLastElec.toStringAsFixed(1)} kWh',
                    ),
                  ),
                  Container(
                      width: 0.5,
                      height: 40,
                      color: AppTheme.textHint.withOpacity(0.2)),
                  Expanded(
                    child: _StatItem(
                      icon: Icons.water_drop,
                      iconColor: AppTheme.waterColor,
                      label: 'Nước',
                      value: '${room.bhRoomLastWater.toStringAsFixed(1)} m³',
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (room.bhRoomUpdateTime != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.update, size: 12, color: AppTheme.textHint),
                const SizedBox(width: 4),
                Text(
                  'Cập nhật: ${_formatDate(room.bhRoomUpdateTime!)}',
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.textHint),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 1 — Quản lý
// ═══════════════════════════════════════════════════════════════════════════

class _ManageTab extends StatelessWidget {
  final BhRoomModel room;
  final Duration remaining;
  final String bhName;
  final String ownerId;
  final String ownerName;

  const _ManageTab({
    required this.room,
    required this.remaining,
    required this.bhName,
    required this.ownerId,
    required this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    switch (room.bhRoomStatus) {
      case BhRoomStatus.available:
        return _AvailableManage(room: room, remaining: remaining);
      case BhRoomStatus.waiting:
        return _WaitingManage(room: room);
      case BhRoomStatus.occupied:
        return _OccupiedManage(
          room: room,
          bhName: bhName,
          ownerId: ownerId,
          ownerName: ownerName,
        );
      case BhRoomStatus.inactive:
        return _InactiveManage(room: room);
    }
  }
}

// ── Available ─────────────────────────────────────────────────────────────

class _AvailableManage extends StatelessWidget {
  final BhRoomModel room;
  final Duration remaining;
  const _AvailableManage({required this.room, required this.remaining});

  String get _countdownText {
    if (remaining == Duration.zero) return '';
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${h > 0 ? '$h:' : ''}$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final hasCode = room.bhRoomCode != null &&
        room.bhRoomCode!.isNotEmpty &&
        remaining > Duration.zero;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCard(
            label: 'Mã liên kết phòng',
            children: [
              if (hasCode) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppTheme.primary.withOpacity(0.2)),
                  ),
                  child: Text(
                    room.bhRoomCode!,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                      color: AppTheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Hết hạn sau $_countdownText',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ] else ...[
                Text(
                  room.bhRoomCode != null && room.bhRoomCode!.isNotEmpty
                      ? 'Mã đã hết hạn'
                      : 'Chưa có mã liên kết cho phòng này.',
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final err = await context
                        .read<BoardingHouseProvider>()
                        .generateRoomCode(room.bhRoomId);
                    if (err != null && context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(err)));
                    }
                  },
                  icon: const Icon(Icons.qr_code_rounded, size: 18),
                  label: Text(hasCode ? 'Tạo mã mới' : 'Tạo mã liên kết'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DangerCard(
            title: 'Xóa phòng',
            description:
                'Phòng trống có thể xóa vĩnh viễn. Hành động này không thể hoàn tác.',
            buttonLabel: 'Xóa phòng',
            onTap: () async {
              final ok = await showConfirmSheet<bool>(
                context,
                title: 'Xóa phòng',
                subtitle: 'Xóa phòng ${room.bhRoomNumber}?',
                confirmLabel: 'Xóa',
                confirmColor: AppTheme.errorColor,
              );
              if (ok == true && context.mounted) {
                await context
                    .read<BoardingHouseProvider>()
                    .deleteRoom(room.bhRoomId);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ── Waiting ───────────────────────────────────────────────────────────────

class _WaitingManage extends StatelessWidget {
  final BhRoomModel room;
  const _WaitingManage({required this.room});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCard(
            label: 'Yêu cầu thuê phòng',
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFF59E0B).withOpacity(0.12),
                    child: Text(
                      room.bhRoomTenantName?.isNotEmpty == true
                          ? room.bhRoomTenantName![0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.bhRoomTenantName ?? 'Không rõ',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        'Đang chờ xác nhận',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFFF59E0B)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectTenant(context),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Từ chối'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _confirmTenant(context),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Xác nhận'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmTenant(BuildContext context) async {
    final ok = await showConfirmSheet<bool>(
      context,
      title: 'Xác nhận cho thuê',
      subtitle:
          'Xác nhận cho ${room.bhRoomTenantName} vào phòng ${room.bhRoomNumber}?',
      confirmLabel: 'Xác nhận',
    );
    if (ok != true || !context.mounted) return;

    final provider = context.read<BoardingHouseProvider>();
    final notifSvc = NotificationService.instance;
    final ownerUid = context.read<AuthProvider>().currentUser!.uid;

    final err = await provider.confirmTenant(room.bhRoomId);
    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    if (room.bhRoomTenantId != null) {
      await notifSvc.createNotification(
        receiverId: room.bhRoomTenantId!,
        senderId: ownerUid,
        type: NotificationType.system,
        content:
            'Yêu cầu thuê phòng ${room.bhRoomNumber} của bạn đã được chấp nhận!',
      );
    }
  }

  Future<void> _rejectTenant(BuildContext context) async {
    final ok = await showConfirmSheet<bool>(
      context,
      title: 'Từ chối',
      subtitle: 'Từ chối yêu cầu của ${room.bhRoomTenantName}?',
      confirmLabel: 'Từ chối',
      confirmColor: AppTheme.errorColor,
    );
    if (ok != true || !context.mounted) return;

    final provider = context.read<BoardingHouseProvider>();
    final notifSvc = NotificationService.instance;
    final ownerUid = context.read<AuthProvider>().currentUser!.uid;
    final tenantId = room.bhRoomTenantId;

    final err = await provider.rejectTenant(room.bhRoomId);
    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    if (tenantId != null) {
      await notifSvc.createNotification(
        receiverId: tenantId,
        senderId: ownerUid,
        type: NotificationType.system,
        content:
            'Yêu cầu thuê phòng ${room.bhRoomNumber} của bạn đã bị từ chối.',
      );
    }
  }
}

// ── Occupied ──────────────────────────────────────────────────────────────

class _OccupiedManage extends StatelessWidget {
  final BhRoomModel room;
  final String bhName;
  final String ownerId;
  final String ownerName;

  const _OccupiedManage({
    required this.room,
    required this.bhName,
    required this.ownerId,
    required this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCard(
            label: 'Người thuê hiện tại',
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.successColor.withOpacity(0.12),
                    child: Text(
                      room.bhRoomTenantName?.isNotEmpty == true
                          ? room.bhRoomTenantName![0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    room.bhRoomTenantName ?? 'Không rõ',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DangerCard(
            title: 'Kết thúc hợp đồng',
            description:
                'Gửi yêu cầu kết thúc hợp đồng đến người thuê. Người thuê sẽ nhận thông báo và cần xác nhận.',
            buttonLabel: 'Gửi yêu cầu ngừng liên kết',
            onTap: () => _handleUnlink(context),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUnlink(BuildContext context) async {
    final ok = await showConfirmSheet<bool>(
      context,
      title: 'Ngừng liên kết',
      subtitle:
          'Gửi yêu cầu kết thúc hợp đồng phòng ${room.bhRoomNumber} đến ${room.bhRoomTenantName}?',
      confirmLabel: 'Gửi yêu cầu',
      confirmColor: AppTheme.errorColor,
    );
    if (ok != true || !context.mounted) return;

    final err = await UnlinkRequestService.instance.sendUnlinkRequest(
      roomId: room.bhRoomId,
      roomNumber: room.bhRoomNumber,
      bhName: bhName,
      ownerId: ownerId,
      ownerName: ownerName,
      tenantId: room.bhRoomTenantId!,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Đã gửi yêu cầu đến ${room.bhRoomTenantName}'),
        backgroundColor:
            err != null ? AppTheme.errorColor : AppTheme.successColor,
      ),
    );
  }
}

// ── Inactive ──────────────────────────────────────────────────────────────

class _InactiveManage extends StatelessWidget {
  final BhRoomModel room;
  const _InactiveManage({required this.room});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCard(
            label: 'Kích hoạt lại phòng',
            children: [
              const Text(
                'Phòng đang ngừng hoạt động. Bạn có thể mở lại để cho thuê.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final ok = await showConfirmSheet<bool>(
                      context,
                      title: 'Mở lại phòng',
                      subtitle: 'Mở lại phòng ${room.bhRoomNumber}?',
                      confirmLabel: 'Mở lại',
                    );
                    if (ok == true && context.mounted) {
                      // TODO: reactivate room
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Mở lại phòng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DangerCard(
            title: 'Xóa vĩnh viễn',
            description:
                'Xóa phòng khỏi hệ thống. Tất cả dữ liệu liên quan sẽ bị mất. Hành động không thể hoàn tác.',
            buttonLabel: 'Xóa vĩnh viễn',
            onTap: () async {
              final ok = await showConfirmSheet<bool>(
                context,
                title: 'Xóa vĩnh viễn',
                subtitle: 'Xóa phòng ${room.bhRoomNumber} vĩnh viễn?',
                confirmLabel: 'Xóa vĩnh viễn',
                confirmColor: AppTheme.errorColor,
              );
              if (ok == true && context.mounted) {
                await context
                    .read<BoardingHouseProvider>()
                    .deleteRoom(room.bhRoomId);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 2 — Đánh giá
// ═══════════════════════════════════════════════════════════════════════════

class _ReviewsTab extends StatelessWidget {
  final RoomReviewProvider provider;
  const _ReviewsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AppTheme.errorColor, size: 48),
              const SizedBox(height: 12),
              Text(provider.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    if (provider.reviews.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined,
                size: 52, color: AppTheme.textHint),
            SizedBox(height: 12),
            Text(
              'Chưa có đánh giá nào',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary),
            ),
            SizedBox(height: 6),
            Text(
              'Đánh giá sẽ xuất hiện khi người thuê gửi',
              style: TextStyle(fontSize: 13, color: AppTheme.textHint),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
            child: RatingsSummaryBar(
              average: provider.averageRating,
              count: provider.reviews.length,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tất cả đánh giá',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...provider.reviews.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ReviewCard(review: r, isOwner: true),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared widgets
// ═══════════════════════════════════════════════════════════════════════════

class _InfoCard extends StatelessWidget {
  final String? label;
  final List<Widget> children;
  const _InfoCard({this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _DangerCard extends StatelessWidget {
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onTap;

  const _DangerCard({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                side: const BorderSide(color: AppTheme.errorColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
