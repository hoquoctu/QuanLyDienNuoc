import 'package:flutter/material.dart';
import 'package:quanlydiennc_app/models/bh_room_model.dart';
import 'package:quanlydiennc_app/theme/app_theme.dart';

/// Widget hiển thị thông tin phòng đang có người thuê.
///
/// Hiển thị:
/// - Tên tenant
/// - Chỉ số điện/nước lần cuối
/// - Nút "Ngừng liên kết" để owner gửi request hủy
///
/// Params:
///   [room]      — Dữ liệu phòng
///   [onUnlink]  — Callback khi owner bấm ngừng liên kết
class OccupiedRoomExpanded extends StatelessWidget {
  final BhRoomModel room;
  final VoidCallback onUnlink;

  const OccupiedRoomExpanded({
    required this.room,
    required this.onUnlink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tenant info ───────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.person,
                    size: 18, color: AppTheme.successColor),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Người thuê',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    room.bhRoomTenantName ?? 'Không rõ',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 14),

          // ── Chỉ số điện nước ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ReadingTile(
                  icon: Icons.bolt,
                  iconColor: const Color(0xFFF59E0B),
                  label: 'Điện cuối',
                  value: '${room.bhRoomLastElec.toStringAsFixed(1)} kWh',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ReadingTile(
                  icon: Icons.water_drop,
                  iconColor: const Color(0xFF3B82F6),
                  label: 'Nước cuối',
                  value: '${room.bhRoomLastWater.toStringAsFixed(1)} m³',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Nút ngừng liên kết ────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: onUnlink,
            icon: const Icon(Icons.link_off, size: 16),
            label: const Text('Ngừng liên kết'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              side: const BorderSide(color: AppTheme.errorColor),
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _ReadingTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textSecondary)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}
