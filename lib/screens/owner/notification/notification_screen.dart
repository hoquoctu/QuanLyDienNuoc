// screens/owner/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/models/notification_model.dart';
import 'package:quanlydiennc_app/providers/auth_provider.dart';
import 'package:quanlydiennc_app/providers/nofitication_provider.dart';
import 'package:quanlydiennc_app/theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  NotificationType? _filter; // null = tất cả
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser!.uid;
      context.read<NotificationProvider>().init(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().currentUser!.uid;
    final notiPvd = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (notiPvd.hasUnread)
            TextButton(
              onPressed: () => notiPvd.markAllAsRead(userId),
              child: const Text(
                'Đọc tất cả',
                style: TextStyle(color: AppTheme.primary, fontSize: 13),
              ),
            ),
        ],
      ),
      body: _buildBody(notiPvd, userId),
    );
  }

  Widget _buildBody(NotificationProvider notiPvd, String userId) {
    if (notiPvd.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notiPvd.error != null) {
      return Center(child: Text(notiPvd.error!));
    }

    // lọc theo filter
    final filtered = _filter == null
        ? notiPvd.items
        : notiPvd.items.where((e) => e.notification.type == _filter).toList();

    return Column(
      children: [
        // ── Bộ lọc ──────────────────────────────────────────────────────
        _FilterBar(
          selected: _filter,
          onChanged: (type) => setState(() => _filter = type),
        ),

        // ── Danh sách ───────────────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? const Center(
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
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _NotifCard(
                      item: item,
                      userId: userId,
                      onDelete: () =>
                          notiPvd.deleteNotification(item.notification.notifId),
                      onTap: () => notiPvd.markAsRead(
                          userId: userId,
                          notificationId: item.notification.notifId),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Filter Bar ────────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final NotificationType? selected;
  final ValueChanged<NotificationType?> onChanged;

  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final filters = [
      (null, 'Tất cả', Icons.notifications_none_outlined),
      (NotificationType.payment, 'Thanh toán', Icons.payments_outlined),
      (NotificationType.room, 'Phòng trọ', Icons.meeting_room_outlined),
      (NotificationType.system, 'Hệ thống', Icons.info_outline),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isActive = selected == f.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onChanged(f.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primary
                        : AppTheme.primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        f.$3,
                        size: 14,
                        color: isActive ? Colors.white : AppTheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        f.$2,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final NotificationItem item; // đổi từ NotificationModel
  final String userId;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _NotifCard({
    required this.item,
    required this.userId,
    required this.onDelete,
    required this.onTap,
  });

  NotificationModel get notif => item.notification;

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
            // highlight nếu chưa đọc
            color:
                item.isRead ? Colors.white : AppTheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: item.isRead
                ? null
                : Border.all(color: AppTheme.primary.withOpacity(0.2)),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, size: 18, color: _color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.content,
                      style: TextStyle(
                        fontSize: 13,
                        // bold nếu chưa đọc
                        fontWeight:
                            item.isRead ? FontWeight.w500 : FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm - dd/MM/yyyy').format(notif.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textHint),
                    ),
                  ],
                ),
              ),
              // dot chưa đọc
              if (!item.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
