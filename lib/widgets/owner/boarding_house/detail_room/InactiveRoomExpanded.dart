import 'package:flutter/material.dart';
import 'package:quanlydiennc_app/models/bh_room_model.dart';
import 'package:quanlydiennc_app/theme/app_theme.dart';

class InactiveRoomExpanded extends StatelessWidget {
  final BhRoomModel room;
  final VoidCallback onReactivate;
  final VoidCallback onDelete;
  const InactiveRoomExpanded(
      {required this.room, required this.onReactivate, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReactivate,
              icon: const Icon(Icons.lock_open_outlined, size: 16),
              label: const Text('Mở lại'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.successColor,
                side: const BorderSide(color: AppTheme.successColor),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_forever, size: 16),
              label: const Text('Xóa phòng'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
