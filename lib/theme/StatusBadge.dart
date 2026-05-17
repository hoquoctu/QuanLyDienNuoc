import 'package:flutter/material.dart';
import '../models/bh_room_model.dart';
import '../services/status_service.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge._({required this.label, required this.color});

  // ── Dùng cho BhRoomStatus (Firestore) ────────────────────────────────────
  factory StatusBadge.bhRoom(BhRoomStatus status) {
    final key = BhRoomModel.statusToKey(status);

    // Tìm tên hiển thị từ StatusCache (type: room)
    final found = StatusCache.statuses.firstWhere(
      (s) => s['type'] == 'room' && s['key'] == key,
      orElse: () => {},
    );
    final label = found['name'] as String? ?? key;

    return StatusBadge._(label: label, color: _colorForRoomStatus(status));
  }

  // ── Dùng cho payment status (nếu cần sau này) ────────────────────────────
  factory StatusBadge.payment(String key) {
    final found = StatusCache.statuses.firstWhere(
      (s) => s['type'] == 'payment' && s['key'] == key,
      orElse: () => {},
    );
    final label = found['name'] as String? ?? key;
    return StatusBadge._(label: label, color: _colorForPaymentKey(key));
  }

  static Color _colorForRoomStatus(BhRoomStatus s) {
    switch (s) {
      case BhRoomStatus.occupied:
        return AppTheme.successColor;
      case BhRoomStatus.roompending:
        return AppTheme.primary;
      case BhRoomStatus.available:
        return AppTheme.textSecondary;
      case BhRoomStatus.inactive:
        return AppTheme.errorColor;
    }
  }

  static Color _colorForPaymentKey(String key) {
    switch (key) {
      case 'paid':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.primary;
      case 'overdue':
        return AppTheme.warningColor;
      case 'cancelled':
      case 'failed':
        return AppTheme.errorColor;
      case 'partial':
        return Colors.orange;
      case 'refunded':
        return Colors.purple;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
