import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

class DetailSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final double prevReading;
  final double currReading;
  final double used;
  final double unitPrice;
  final double total;
  final String unit;
  final NumberFormat fmt;
  const DetailSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.prevReading,
    required this.currReading,
    required this.used,
    required this.unitPrice,
    required this.total,
    required this.unit,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ReadRow(
                  label: 'Chỉ số cũ',
                  value: '${fmt.format(prevReading)} $unit'),
              const Icon(Icons.arrow_forward,
                  size: 16, color: AppTheme.textHint),
              ReadRow(
                  label: 'Chỉ số mới',
                  value: '${fmt.format(currReading)} $unit'),
              ReadRow(
                  label: 'Tiêu thụ',
                  value: '${fmt.format(used)} $unit',
                  bold: true),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  '${fmt.format(used)} $unit × ${fmt.format(unitPrice)}đ/$unit',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
              Text('${fmt.format(total)}đ',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

class ReadRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const ReadRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppTheme.textHint)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: bold
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary)),
      ],
    );
  }
}
