import 'package:flutter/material.dart';
import 'package:quanlydiennc_app/models/bh_room_model.dart';

import 'package:quanlydiennc_app/models/boarding_house_model.dart';
import 'package:quanlydiennc_app/theme/app_theme.dart';
import 'package:quanlydiennc_app/widgets/owner/boarding_house/StatChip.dart';

// ═══════════════════════════════════════════════════════════════════════════
// HEADER DÃY TRỌ
// ═══════════════════════════════════════════════════════════════════════════

class BhHeader extends StatelessWidget {
  final BoardingHouseModel bh;
  final List<BhRoomModel> rooms;
  final bool editMode;
  final TextEditingController nameCtrl;
  final TextEditingController addrCtrl;
  final TextEditingController descCtrl;

  const BhHeader({
    required this.bh,
    required this.rooms,
    required this.editMode,
    required this.nameCtrl,
    required this.addrCtrl,
    required this.descCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final occupiedCount =
        rooms.where((r) => r.bhRoomStatus == BhRoomStatus.occupied).length;
    final emptyCount =
        rooms.where((r) => r.bhRoomStatus == BhRoomStatus.available).length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: editMode
          ? _BhEditForm(
              nameCtrl: nameCtrl,
              addrCtrl: addrCtrl,
              descCtrl: descCtrl,
            )
          : _BhInfoDisplay(
              bh: bh,
              totalRooms: rooms.length,
              occupiedCount: occupiedCount,
              emptyCount: emptyCount,
            ),
    );
  }
}

class _BhEditForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController addrCtrl;
  final TextEditingController descCtrl;

  const _BhEditForm({
    required this.nameCtrl,
    required this.addrCtrl,
    required this.descCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: nameCtrl,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(
            labelText: 'Tên dãy trọ',
            labelStyle: TextStyle(color: Colors.white70),
            fillColor: Colors.white24,
            filled: true,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: addrCtrl,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Địa chỉ',
            labelStyle: TextStyle(color: Colors.white60),
            fillColor: Colors.white24,
            filled: true,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: descCtrl,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Mô tả',
            labelStyle: TextStyle(color: Colors.white60),
            fillColor: Colors.white24,
            filled: true,
          ),
        ),
      ],
    );
  }
}

class _BhInfoDisplay extends StatelessWidget {
  final BoardingHouseModel bh;
  final int totalRooms;
  final int occupiedCount;
  final int emptyCount;

  const _BhInfoDisplay({
    required this.bh,
    required this.totalRooms,
    required this.occupiedCount,
    required this.emptyCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          bh.bhName,
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          bh.bhAddress,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        if (bh.bhDescription.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            bh.bhDescription,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatChip(label: '$totalRooms', desc: 'Tổng phòng'),
            const SizedBox(width: 20),
            StatChip(label: '$occupiedCount', desc: 'Đang thuê'),
            const SizedBox(width: 20),
            StatChip(label: '$emptyCount', desc: 'Trống'),
          ],
        ),
      ],
    );
  }
}
