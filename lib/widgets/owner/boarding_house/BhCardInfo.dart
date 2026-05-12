import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:quanlydiennc_app/models/boarding_house_model.dart';
import 'package:quanlydiennc_app/theme/app_theme.dart';
import 'package:quanlydiennc_app/widgets/owner/boarding_house/InfoChip.dart';

class BhCardInfo extends StatelessWidget {
  final BoardingHouseModel bh;
  final int totalRooms;
  final int rentedRooms;

  const BhCardInfo({
    required this.bh,
    required this.totalRooms,
    required this.rentedRooms,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          bh.bhName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          bh.bhAddress,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            InfoChip(
              icon: Icons.door_front_door_outlined,
              label: '$totalRooms phòng',
            ),
            const SizedBox(width: 8),
            InfoChip(
              icon: Icons.people_outline,
              label: '$rentedRooms đã thuê',
              color: AppTheme.successColor,
            ),
          ],
        ),
      ],
    );
  }
}
