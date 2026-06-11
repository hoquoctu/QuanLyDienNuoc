import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/models/unlink_request_model.dart';
import 'package:quanlydiennc_app/providers/user/bh_room_provider.dart';
import 'package:quanlydiennc_app/services/manager/unlink_request_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/bh_room_model.dart';
import '../../models/boarding_house_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user/mini_stat.dart';

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
  BhRoomProviderUser? _bhRoomProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        _bhRoomProvider = context.read<BhRoomProviderUser>();
        _bhRoomProvider!.initForUser(user.uid);
        _bhRoomProvider!.addListener(_onProviderChanged);
      }
    });
  }

  void _onProviderChanged() {
    final provider = context.read<BhRoomProviderUser>();
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
              context.read<BhRoomProviderUser>().clearCancelledFlag();
              Navigator.pop(ctx);
            },
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinRoom() async {
    if (_codeCtrl.text.trim().isEmpty) {
      setState(() => _err = 'Vui lòng nhập mã phòng');
      return;
    }
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      setState(() => _err = 'Phiên đăng nhập đã hết hạn');
      return;
    }
    setState(() {
      _err = null;
      _joining = true;
    });
    final err = await context
        .read<BhRoomProviderUser>()
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

  // ── Tenant đồng ý rời phòng ───────────────────────────────────────────────
  Future<void> _handleAcceptUnlink(
      BhRoomModel room, UnlinkRequestModel req) async {
    final user = context.read<AuthProvider>().currentUser!;
    final err = await UnlinkRequestService.instance.acceptUnlink(
      requestId: req.requestId,
      roomId: room.bhRoomId,
      tenantId: user.uid,
      tenantName: user.name,
      ownerId: req.ownerId,
      roomNumber: room.bhRoomNumber,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? 'Đã đồng ý rời phòng ${room.bhRoomNumber}'),
      backgroundColor:
          err != null ? AppTheme.errorColor : AppTheme.successColor,
    ));
  }

  // ── Tenant từ chối rời phòng ─────────────────────────────────────────────
  Future<void> _handleRejectUnlink(
      BhRoomModel room, UnlinkRequestModel req) async {
    final user = context.read<AuthProvider>().currentUser!;
    final err = await UnlinkRequestService.instance.rejectUnlink(
      requestId: req.requestId,
      tenantId: user.uid,
      tenantName: user.name,
      ownerId: req.ownerId,
      roomNumber: room.bhRoomNumber,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? 'Đã từ chối yêu cầu'),
      backgroundColor:
          err != null ? AppTheme.errorColor : AppTheme.successColor,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BhRoomProviderUser>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Phòng trọ của tôi')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? _buildError(provider.error!)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (provider.rooms.isNotEmpty) ...[
                        _buildRoomCount(provider),
                        const SizedBox(height: 12),
                        // Wrap từng phòng occupied vào StreamBuilder
                        ...provider.rooms.map((room) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: room.bhRoomStatus == BhRoomStatus.occupied
                                  ? _RoomCardWithUnlinkStream(
                                      room: room,
                                      bh: provider.boardingHouseFor(room.bhId),
                                      onAccept: _handleAcceptUnlink,
                                      onReject: _handleRejectUnlink,
                                    )
                                  : _buildRoomCard(
                                      room,
                                      provider.boardingHouseFor(room.bhId),
                                      null,
                                    ),
                            )),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                      ],
                      _buildJoinSection(provider.rooms.isEmpty),
                    ],
                  ),
                ),
    );
  }

  Widget _buildRoomCount(BhRoomProviderUser provider) {
    final active = provider.activeRooms.length;
    final waiting = provider.waitingRooms.length;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.home, color: AppTheme.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${provider.rooms.length} phòng',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppTheme.textPrimary)),
            Text(
              '${active > 0 ? '$active đang thuê' : ''}${active > 0 && waiting > 0 ? ' · ' : ''}${waiting > 0 ? '$waiting chờ xác nhận' : ''}',
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  // ── Card phòng (nhận thêm pendingRequest) ────────────────────────────────
  Widget _buildRoomCard(
    BhRoomModel room,
    BoardingHouseModel? bh,
    UnlinkRequestModel? pendingRequest,
  ) {
    final isWaiting = room.bhRoomStatus == BhRoomStatus.waiting;
    final statusColor =
        isWaiting ? const Color(0xFFF59E0B) : AppTheme.successColor;
    final statusLabel = isWaiting ? 'Chờ xác nhận' : 'Đang thuê';
    final statusIcon =
        isWaiting ? Icons.hourglass_top_rounded : Icons.check_circle;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: pendingRequest != null
            ? Border.all(
                color: AppTheme.errorColor.withOpacity(0.4), width: 1.5)
            : isWaiting
                ? Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3))
                : null,
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
          // ── Header ────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.home, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bh != null)
                      Text(bh.bhName,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                    Text('Phòng ${room.bhRoomNumber}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: AppTheme.textPrimary)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(statusLabel,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor)),
                  ],
                ),
              ),
            ],
          ),

          // ── Đang thuê: chỉ số điện nước ──────────────────────────────
          if (!isWaiting) ...[
            const SizedBox(height: 14),
            const Divider(height: 0),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: MiniStat(
                    icon: Icons.bolt,
                    iconColor: AppTheme.elecColor,
                    label: 'Điện',
                    value: '${room.bhRoomLastElec.toStringAsFixed(1)} kWh',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MiniStat(
                    icon: Icons.water_drop,
                    iconColor: AppTheme.waterColor,
                    label: 'Nước',
                    value: '${room.bhRoomLastWater.toStringAsFixed(1)} m³',
                  ),
                ),
              ],
            ),
            if (bh != null && bh.bhAddress.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 14, color: AppTheme.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(bh.bhAddress,
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textHint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],

            // ── Banner + nút unlink nếu có pending request ────────────
            if (pendingRequest != null) ...[
              const SizedBox(height: 14),
              const Divider(height: 0),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AppTheme.errorColor.withOpacity(0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.link_off, color: AppTheme.errorColor, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chủ trọ muốn kết thúc hợp đồng phòng này',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _handleRejectUnlink(room, pendingRequest),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: AppTheme.textSecondary),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Từ chối'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _handleAcceptUnlink(room, pendingRequest),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Đồng ý rời'),
                    ),
                  ),
                ],
              ),
            ],
          ],

          // ── Chờ xác nhận ─────────────────────────────────────────────
          if (isWaiting) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.mark_email_unread_outlined,
                      color: Color(0xFFF59E0B), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đang chờ chủ trọ xét duyệt yêu cầu',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJoinSection(bool noRooms) {
    return Column(
      children: [
        if (noRooms) ...[
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
                const Text('Chưa có phòng trọ',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppTheme.textPrimary)),
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
        ] else ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add_home,
                    color: AppTheme.successColor, size: 18),
              ),
              const SizedBox(width: 8),
              const Text('Thêm phòng mới',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
        ],
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
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.warningColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.warningColor, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mã phòng có hiệu lực trong 30 phút kể từ khi chủ trọ tạo.',
                  style: TextStyle(fontSize: 12, color: AppTheme.warningColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: AppTheme.errorColor, size: 48),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Widget bọc StreamBuilder cho phòng occupied
// ═══════════════════════════════════════════════════════════════════════════

class _RoomCardWithUnlinkStream extends StatelessWidget {
  final BhRoomModel room;
  final BoardingHouseModel? bh;
  final Future<void> Function(BhRoomModel, UnlinkRequestModel) onAccept;
  final Future<void> Function(BhRoomModel, UnlinkRequestModel) onReject;

  const _RoomCardWithUnlinkStream({
    required this.room,
    required this.bh,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UnlinkRequestModel?>(
      stream: UnlinkRequestService.instance
          .streamPendingRequestForRoom(room.bhRoomId),
      builder: (context, snapshot) {
        final pendingRequest = snapshot.data;
        // Gọi lại _buildRoomCard từ parent state
        return (context.findAncestorStateOfType<_RoomUserScreenState>()!)
            ._buildRoomCard(room, bh, pendingRequest);
      },
    );
  }
}
