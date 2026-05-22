import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SettingsInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const SettingsInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textHint),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
