import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quanlydiennc_app/providers/nofitication_provider.dart';
import '../../models/notification_model.dart';
import '../../theme/app_theme.dart';

class NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const NotificationTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final notif = item.notification;
    final isRead = item.isRead;

    late final IconData icon;
    late final Color iconColor;
    late final Color iconBg;

    switch (notif.type) {
      case NotificationType.payment:
        icon = Icons.payment_rounded;
        iconColor = AppTheme.successColor;
        iconBg = AppTheme.successColor.withOpacity(0.1);
        break;
      case NotificationType.room:
        icon = Icons.home_rounded;
        iconColor = AppTheme.primary;
        iconBg = AppTheme.primary.withOpacity(0.1);
        break;
      case NotificationType.system:
        icon = Icons.info_rounded;
        iconColor = AppTheme.waterColor;
        iconBg = AppTheme.waterColor.withOpacity(0.1);
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : AppTheme.primary.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead
                ? Colors.transparent
                : AppTheme.primary.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.content,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(notif.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textHint,
                    ),
                  ),
                ],
              ),
            ),
            if (!isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';

    return DateFormat('dd/MM/yyyy · HH:mm').format(dt);
  }
}
