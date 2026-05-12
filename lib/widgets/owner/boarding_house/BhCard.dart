import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:quanlydiennc_app/models/boarding_house_model.dart';
import 'package:quanlydiennc_app/theme/app_theme.dart';
import 'package:quanlydiennc_app/widgets/owner/boarding_house/BhCardInfo.dart';

class BhCard extends StatelessWidget {
  final BoardingHouseModel bh;
  final int totalRooms;
  final int rentedRooms;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const BhCard({
    required this.bh,
    required this.totalRooms,
    required this.rentedRooms,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _BhIconBox(),
            const SizedBox(width: 16),
            Expanded(
              child: BhCardInfo(
                bh: bh,
                totalRooms: totalRooms,
                rentedRooms: rentedRooms,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.errorColor, size: 20),
              onPressed: onDelete,
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }
}

class _BhIconBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.apartment, color: AppTheme.primary, size: 28),
    );
  }
}
