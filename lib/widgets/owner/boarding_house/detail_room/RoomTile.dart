// ═══════════════════════════════════════════════════════════════════════════
// ROOM TILE
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/models/bh_room_model.dart';
import 'package:quanlydiennc_app/providers/boarding_house_provider.dart';
import 'package:quanlydiennc_app/theme/app_theme.dart';
import './InactiveRoomExpanded.dart';
import './PendingRoomExpanded.dart';
import './EmptyRoomExpanded.dart';
import '../../../../theme/StatusBadge.dart';
import '../../../../widgets/bottom_sheet_confirm.dart';

class RoomTile extends StatefulWidget {
  final BhRoomModel room;
  const RoomTile({required this.room, super.key});
  @override
  State<RoomTile> createState() => _RoomTileState();
}

class _RoomTileState extends State<RoomTile> {
  bool _expanded = false;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.room.bhRoomCodeExpiry == null) return; // ← dừng sớm
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateRemaining();
    });
  }

  void _updateRemaining() {
    final expiry = widget.room.bhRoomCodeExpiry;
    if (expiry == null) {
      _timer?.cancel();
      return;
    }
    final diff = expiry.difference(DateTime.now());
    if (diff.isNegative) {
      // Hết hạn → reset code trên Firestore
      _timer?.cancel();
      setState(() => _remaining = Duration.zero);
      context.read<BoardingHouseProvider>().resetRoomCode(widget.room.bhRoomId);
      return;
    }
    setState(() => _remaining = diff);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(RoomTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Khi Firestore push data mới (có code mới) → restart timer
    if (oldWidget.room.bhRoomCode != widget.room.bhRoomCode) {
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
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
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              // TODO: navigate to RoomDetailScreen khi làm trang đó
              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _RoomNumberBox(room: room),
                  const SizedBox(width: 12),
                  Expanded(child: _RoomTileInfo(room: room)),
                  StatusBadge.bhRoom(room.bhRoomStatus),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppTheme.textHint,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) _buildExpandedContent(context, room),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, BhRoomModel room) {
    print(room);
    switch (room.bhRoomStatus) {
      // phòng trống
      case BhRoomStatus.empty:
        return EmptyRoomExpanded(
          room: room,
          remaining: _remaining,
          onGenCode: () async {
            final err = await context
                .read<BoardingHouseProvider>()
                .generateRoomCode(room.bhRoomId);
            if (err != null && context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(err)));
            }
          },
        );
      //phòng đang chờ xác nhận (user đã gửi yêu cầu)
      case BhRoomStatus.waiting:
        return PendingRoomExpanded(
          room: room,
          onConfirm: () async {
            final ok = await showConfirmSheet<bool>(
              context,
              title: 'Xác nhận cho thuê',
              subtitle:
                  'Xác nhận cho ${room.bhRoomTenantName} vào phòng ${room.bhRoomNumber}?',
              confirmLabel: 'Xác nhận',
            );
            if (ok == true && context.mounted) {
              // TODO: confirm tenant
            }
          },
          onReject: () async {
            final ok = await showConfirmSheet<bool>(
              context,
              title: 'Từ chối',
              subtitle: 'Từ chối yêu cầu của ${room.bhRoomTenantName}?',
              confirmLabel: 'Từ chối',
              confirmColor: AppTheme.errorColor,
            );
            if (ok == true && context.mounted) {
              // TODO: reject tenant
            }
          },
        );
      //phòng đang chờ xác nhận (pending — dự phòng)
      case BhRoomStatus.pending:
        return PendingRoomExpanded(
          room: room,
          onConfirm: () async {
            final ok = await showConfirmSheet<bool>(
              context,
              title: 'Xác nhận cho thuê',
              subtitle:
                  'Xác nhận cho ${room.bhRoomTenantName} vào phòng ${room.bhRoomNumber}?',
              confirmLabel: 'Xác nhận',
            );
            if (ok == true && context.mounted) {
              // TODO: confirm tenant
            }
          },
          onReject: () async {
            final ok = await showConfirmSheet<bool>(
              context,
              title: 'Từ chối',
              subtitle: 'Từ chối yêu cầu của ${room.bhRoomTenantName}?',
              confirmLabel: 'Từ chối',
              confirmColor: AppTheme.errorColor,
            );
            if (ok == true && context.mounted) {
              // TODO: reject tenant
            }
          },
        );
      //phòng có
      case BhRoomStatus.occupied:
        return const SizedBox();
      //phòng xóa
      case BhRoomStatus.inactive:
        return InactiveRoomExpanded(
          room: room,
          onReactivate: () async {
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
          onDelete: () async {
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
                  .deleteRoom(room.bhRoomId, room.bhRoomStatus);
            }
          },
        );
    }
  }
}

class _RoomNumberBox extends StatelessWidget {
  final BhRoomModel room;
  const _RoomNumberBox({required this.room});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(room.bhRoomStatus);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          room.bhRoomNumber.length > 4
              ? room.bhRoomNumber.substring(room.bhRoomNumber.length - 3)
              : room.bhRoomNumber,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: color,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Color _statusColor(BhRoomStatus s) {
    switch (s) {
      case BhRoomStatus.occupied:
        return AppTheme.successColor;
      case BhRoomStatus.waiting:
        return AppTheme.warningColor;
      case BhRoomStatus.pending:
        return AppTheme.primary;
      case BhRoomStatus.empty:
        return AppTheme.textSecondary;
      case BhRoomStatus.inactive:
        return AppTheme.errorColor;

    }
  }
}

class _RoomTileInfo extends StatelessWidget {
  final BhRoomModel room;
  const _RoomTileInfo({required this.room});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          room.bhRoomNumber,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        if (room.bhRoomTenantName != null)
          Text(
            room.bhRoomTenantName!,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
      ],
    );
  }
}
