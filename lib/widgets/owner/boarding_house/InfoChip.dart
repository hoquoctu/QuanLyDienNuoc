// ═══════════════════════════════════════════════════════════════════════════
// CHIP THÔNG TIN NHỎ
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:quanlydiennc_app/theme/app_theme.dart';

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const InfoChip({
    required this.icon,
    required this.label,
    this.color = AppTheme.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
