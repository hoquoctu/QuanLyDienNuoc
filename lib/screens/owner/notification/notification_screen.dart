// screens/owner/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/models/notification_model.dart';
import 'package:quanlydiennc_app/providers/auth_provider.dart';
import 'package:quanlydiennc_app/providers/nofitication_provider.dart';
import 'package:quanlydiennc_app/theme/app_theme.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().currentUser!.uid;
    final notiPvd = context.read<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          TextButton(
            onPressed: () => notiPvd.markAllAsRead(userId),
            child: const Text(
              'Đọc tất cả',
              style: TextStyle(color: AppTheme.primary, fontSize: 13),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notiPvd.streamNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data ?? [];

          if (all.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_outlined,
                      size: 48, color: AppTheme.textHint),
                  SizedBox(height: 8),
                  Text('Chưa có thông báo',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            );
          }

          // Nhóm theo type
          final payment =
              all.where((e) => e.type == NotificationType.payment).toList();
          final system =
              all.where((e) => e.type == NotificationType.system).toList();
          final room =
              all.where((e) => e.type == NotificationType.room).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (payment.isNotEmpty) ...[
                _GroupHeader(
                  icon: Icons.payments_outlined,
                  label: 'Thanh toán',
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 8),
                ...payment.map((n) => _NotifCard(
                      notif: n,
                      userId: userId,
                      onDelete: () => notiPvd.deleteNotification(n.notifId),
                      onTap: () => notiPvd.markAsRead(
                        userId: userId,
                        notificationId: n.notifId,
                      ),
                    )),
                const SizedBox(height: 16),
              ],
              if (room.isNotEmpty) ...[
                _GroupHeader(
                  icon: Icons.meeting_room_outlined,
                  label: 'Phòng trọ',
                  color: Colors.orange,
                ),
                const SizedBox(height: 8),
                ...room.map((n) => _NotifCard(
                      notif: n,
                      userId: userId,
                      onDelete: () => notiPvd.deleteNotification(n.notifId),
                      onTap: () => notiPvd.markAsRead(
                        userId: userId,
                        notificationId: n.notifId,
                      ),
                    )),
                const SizedBox(height: 16),
              ],
              if (system.isNotEmpty) ...[
                _GroupHeader(
                  icon: Icons.info_outline,
                  label: 'Hệ thống',
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 8),
                ...system.map((n) => _NotifCard(
                      notif: n,
                      userId: userId,
                      onDelete: () => notiPvd.deleteNotification(n.notifId),
                      onTap: () => notiPvd.markAsRead(
                        userId: userId,
                        notificationId: n.notifId,
                      ),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _GroupHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: color.withOpacity(0.3))),
      ],
    );
  }
}

class _NotifCard extends StatelessWidget {
  final NotificationModel notif;
  final String userId;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _NotifCard({
    required this.notif,
    required this.userId,
    required this.onDelete,
    required this.onTap,
  });

  IconData get _icon {
    switch (notif.type) {
      case NotificationType.payment:
        return Icons.receipt_long_outlined;
      case NotificationType.room:
        return Icons.meeting_room_outlined;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  Color get _color {
    switch (notif.type) {
      case NotificationType.payment:
        return AppTheme.primary;
      case NotificationType.room:
        return Colors.orange;
      case NotificationType.system:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notif.notifId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, size: 18, color: _color),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.content,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm - dd/MM/yyyy').format(notif.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
