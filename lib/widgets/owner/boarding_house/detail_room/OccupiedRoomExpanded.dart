import 'package:flutter/material.dart';
import 'package:quanlydiennc_app/models/bh_room_model.dart';
import 'package:quanlydiennc_app/models/unlink_request_model.dart';
import 'package:quanlydiennc_app/services/manager/unlink_request_service.dart';
import 'package:quanlydiennc_app/theme/app_theme.dart';

class OccupiedRoomExpanded extends StatefulWidget {
  final BhRoomModel room;
  final VoidCallback onUnlink;

  const OccupiedRoomExpanded({
    required this.room,
    required this.onUnlink,
    super.key,
  });

  @override
  State<OccupiedRoomExpanded> createState() => _OccupiedRoomExpandedState();
}

class _OccupiedRoomExpandedState extends State<OccupiedRoomExpanded> {
  bool _cancelling = false;

  Future<void> _handleCancel(String requestId) async {
    setState(() => _cancelling = true);
    final err =
        await UnlinkRequestService.instance.cancelUnlinkRequest(requestId);
    if (!mounted) return;
    setState(() => _cancelling = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UnlinkRequestModel?>(
      stream: UnlinkRequestService.instance
          .streamPendingRequestForRoom(widget.room.bhRoomId),
      builder: (context, snapshot) {
        final pendingRequest = snapshot.data;

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
              // ── Tenant info ──────────────────────────────────────────
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
                      const Text('Người thuê',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500)),
                      Text(
                        widget.room.bhRoomTenantName ?? 'Không rõ',
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

              // ── Chỉ số điện nước ─────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _ReadingTile(
                      icon: Icons.bolt,
                      iconColor: const Color(0xFFF59E0B),
                      label: 'Điện cuối',
                      value:
                          '${widget.room.bhRoomLastElec.toStringAsFixed(1)} kWh',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ReadingTile(
                      icon: Icons.water_drop,
                      iconColor: const Color(0xFF3B82F6),
                      label: 'Nước cuối',
                      value:
                          '${widget.room.bhRoomLastWater.toStringAsFixed(1)} m³',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Pending badge ────────────────────────────────────────
              if (pendingRequest != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_top, size: 14, color: Colors.orange),
                      SizedBox(width: 6),
                      Text(
                        'Đang chờ tenant xác nhận...',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _cancelling
                    ? const Center(child: CircularProgressIndicator())
                    : OutlinedButton.icon(
                        onPressed: () =>
                            _handleCancel(pendingRequest.requestId),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Hủy yêu cầu'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: const BorderSide(color: AppTheme.textSecondary),
                          minimumSize: const Size(double.infinity, 40),
                        ),
                      ),
              ] else
                OutlinedButton.icon(
                  onPressed: widget.onUnlink,
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
      },
    );
  }
}

// _ReadingTile giữ nguyên như cũ
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
