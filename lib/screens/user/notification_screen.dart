import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/providers/auth_provider.dart';
import 'package:quanlydiennc_app/providers/nofitication_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user/notification_tile.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Gọi sau frame đầu để context sẵn sàng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser!.uid;
      context.read<NotificationProvider>().init(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pvd = context.watch<NotificationProvider>();
    final userId = context.read<AuthProvider>().currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          if (pvd.hasUnread)
            TextButton(
              onPressed: () => pvd.markAllAsRead(userId),
              child: const Text(
                'Đọc tất cả',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(pvd, userId),
    );
  }

  Widget _buildBody(NotificationProvider pvd, String userId) {
    if (pvd.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pvd.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppTheme.errorColor, size: 48),
              const SizedBox(height: 12),
              Text(pvd.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    if (pvd.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppTheme.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có thông báo',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Bạn sẽ nhận thông báo khi có cập nhật mới',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: pvd.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = pvd.items[index];
        return NotificationTile(
          item: item,
          onTap: () {
            if (!item.isRead) {
              pvd.markAsRead(
                  userId: userId, notificationId: item.notification.notifId);
            }
          },
        );
      },
    );
  }
}
