import 'package:flutter/material.dart';
import 'package:quanlydiennc_app/theme/app_theme.dart';
import 'package:quanlydiennc_app/models/bh_room_model.dart';
import 'package:flutter/services.dart';

/// Widget hiển thị phần mở rộng của phòng trống.
///
/// Có 2 trạng thái:
/// - [room.bhRoomCode] == null → Hiển thị nút "Tạo mã tham gia"
/// - [room.bhRoomCode] != null → Hiển thị mã phòng + đếm ngược hết hạn
///
/// Params:
///   [room]      — Dữ liệu phòng (BhRoomModel)
///   [remaining] — Thời gian còn lại trước khi mã hết hạn
///   [onGenCode] — Callback được gọi khi bấm "Tạo mã tham gia"

class EmptyRoomExpanded extends StatelessWidget {
  final BhRoomModel room;
  final Duration remaining;
  final VoidCallback onGenCode;
  const EmptyRoomExpanded(
      {required this.room, required this.remaining, required this.onGenCode});

  @override
  Widget build(BuildContext context) {
    final hasCode = room.bhRoomCode != null;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: hasCode
          ? Column(
              children: [
                const Text('Mã tham gia phòng',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        fontSize: 12)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: room.bhRoomCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép mã!')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          room.bhRoomCode!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.copy,
                            size: 16, color: AppTheme.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 14, color: AppTheme.warningColor),
                    const SizedBox(width: 4),
                    Text(
                      'Hết hạn sau: ${_fmt(remaining)}',
                      style: const TextStyle(
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                const Text('Phòng chưa có người thuê',
                    style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onGenCode,
                  icon: const Icon(Icons.qr_code, size: 16),
                  label: const Text('Tạo mã tham gia'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40)),
                ),
              ],
            ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
