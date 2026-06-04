import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class InfoCard extends StatelessWidget {
  final String? title;
  final IconData? titleIcon;
  final Color? titleColor;
  final List<Widget> children;

  const InfoCard({
    this.title,
    this.titleIcon,
    this.titleColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          if (title != null) ...[
            Row(
              children: [
                if (titleIcon != null)
                  Icon(titleIcon, color: titleColor, size: 18),
                if (titleIcon != null) const SizedBox(width: 6),
                Text(title!,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: titleColor ?? AppTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 0),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}
