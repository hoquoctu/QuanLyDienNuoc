import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final double? trend;
  const StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppTheme.textPrimary)),
          if (trend != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(trend! >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: trend! >= 0
                        ? AppTheme.errorColor
                        : AppTheme.successColor,
                    size: 14),
                const SizedBox(width: 2),
                Text(
                  '${trend!.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: trend! >= 0
                          ? AppTheme.errorColor
                          : AppTheme.successColor),
                ),
              ],
            )
          ],
        ],
      ),
    );
  }
}
