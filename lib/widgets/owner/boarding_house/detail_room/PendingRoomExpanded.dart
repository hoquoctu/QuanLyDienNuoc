import 'package:flutter/material.dart';
import 'package:quanlydiennc_app/theme/app_theme.dart';
import 'package:quanlydiennc_app/models/bh_room_model.dart';

/// Widget hiển thị phần mở rộng khi có người gửi yêu cầu thuê phòng.
///
/// Hiển thị tên người thuê và 2 nút hành động để chủ nhà xử lý.
///
/// Params:
///   [room]      — Dữ liệu phòng, lấy tên người thuê từ [bhRoomTenantName]
///   [onConfirm] — Callback được gọi khi bấm "Chấp nhận"
///   [onReject]  — Callback được gọi khi bấm "Từ chối"
class PendingRoomExpanded extends StatelessWidget {
  final BhRoomModel room;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  const PendingRoomExpanded(
      {required this.room, required this.onConfirm, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Yêu cầu tham gia',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                  fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                room.bhRoomTenantName ?? 'Người dùng',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                  ),
                  child: const Text('Từ chối'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor),
                  child: const Text('Chấp nhận'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
