import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/providers/nofitication_provider.dart';
import '../../theme/app_theme.dart';
import '../../screens/user/notification_screen.dart';
import '../../providers/auth_provider.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final notifPvd = context.watch<NotificationProvider>();
    final userId = context.read<AuthProvider>().currentUser?.uid;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationScreen()),
      ),
      child: StreamBuilder<int>(
        stream: notifPvd.streamUnreadCount(userId!),
        builder: (context, snapshot) {
          final unread = snapshot.data ?? 0;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined,
                  color: Colors.white, size: 24),
              if (unread > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: const BoxDecoration(
                      color: AppTheme.errorColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
