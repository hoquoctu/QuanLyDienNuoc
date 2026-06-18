import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/models/bh_room_model.dart';
import 'package:quanlydiennc_app/providers/owner/room_review_provider.dart';
import 'package:quanlydiennc_app/services/manager/boarding_house_service.dart';
import 'package:quanlydiennc_app/theme/app_theme.dart';
import 'package:quanlydiennc_app/widgets/bottom_sheet_confirm.dart';
import 'package:quanlydiennc_app/screens/owner/room_block/room_detail_owner_screen.dart';

/// RoomTile dành cho owner — bấm vào mở màn hình detail riêng
/// (Tab thông tin + Tab đánh giá)
class RoomTile extends StatelessWidget {
  final BhRoomModel room;
  final String bhName;
  final String ownerId;
  final String ownerName;

  const RoomTile({
    super.key,
    required this.room,
    required this.bhName,
    required this.ownerId,
    required this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    final isOccupied = room.bhRoomStatus == BhRoomStatus.occupied;
    final isWaiting = room.bhRoomStatus == BhRoomStatus.waiting;
    final isAvailable = room.bhRoomStatus == BhRoomStatus.available;
    final isInactive = room.bhRoomStatus == BhRoomStatus.inactive;

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
      statusColor = AppTheme.textHint;
      statusLabel = 'Ngừng HĐ';
      statusIcon = Icons.block_outlined;
    }

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isInactive ? AppTheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isWaiting
              ? Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.4), width: 1.5)
              : null,
          boxShadow: isInactive
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // ── Icon phòng ───────────────────────────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.home, color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),

            // ── Tên phòng + tenant ───────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phòng ${room.bhRoomNumber}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color:
                          isInactive ? AppTheme.textHint : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (isOccupied && room.bhRoomTenantName != null)
                    Text(
                      room.bhRoomTenantName!,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (isWaiting && room.bhRoomTenantName != null)
                    Text(
                      '${room.bhRoomTenantName} • Chờ duyệt',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      isInactive ? 'Ngừng hoạt động' : 'Phòng trống',
                      style: TextStyle(
                          fontSize: 12,
                          color: isInactive
                              ? AppTheme.textHint
                              : AppTheme.textSecondary),
                    ),
                ],
              ),
            ),

            // ── Badge trạng thái + actions ───────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        statusLabel,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Actions row
                Row(
                  children: [
                    // Nút xác nhận / từ chối khi có người chờ
                    if (isWaiting) ...[
                      _SmallActionBtn(
                        icon: Icons.close,
                        color: AppTheme.errorColor,
                        onTap: () => _rejectTenant(context),
                      ),
                      const SizedBox(width: 6),
                      _SmallActionBtn(
                        icon: Icons.check,
                        color: AppTheme.successColor,
                        onTap: () => _confirmTenant(context),
                      ),
                    ],
                    // Chevron luôn hiển thị
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right,
                        size: 16, color: AppTheme.textHint),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Navigate sang màn hình detail ────────────────────────────────────────
  void _openDetail(BuildContext context) {
    context.read<RoomReviewProvider>().reset();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<RoomReviewProvider>(),
          child: RoomDetailOwnerScreen(
            room: room,
            bhName: bhName,
            ownerId: ownerId, // ← thêm dòng này
            ownerName: ownerName, // ← thêm dòng này
          ),
        ),
      ),
    );
  }

  // ── Confirm / Reject tenant ──────────────────────────────────────────────
  Future<void> _confirmTenant(BuildContext context) async {
    final ok = await showConfirmSheet<bool>(
      context,
      title: 'Xác nhận người thuê',
      subtitle:
          'Chấp nhận "${room.bhRoomTenantName}" vào phòng ${room.bhRoomNumber}?',
      confirmLabel: 'Xác nhận',
    );
    if (ok == true && context.mounted) {
      final err =
          await BoardingHouseService.instance.confirmTenant(room.bhRoomId);
      if (err != null && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }

  Future<void> _rejectTenant(BuildContext context) async {
    final ok = await showConfirmSheet<bool>(
      context,
      title: 'Từ chối người thuê',
      subtitle:
          'Từ chối "${room.bhRoomTenantName}" vào phòng ${room.bhRoomNumber}?',
      confirmLabel: 'Từ chối',
      confirmColor: AppTheme.errorColor,
    );
    if (ok == true && context.mounted) {
      final err =
          await BoardingHouseService.instance.rejectTenant(room.bhRoomId);
      if (err != null && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }
}

// ── Small icon button ─────────────────────────────────────────────────────
class _SmallActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SmallActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
