// providers/notification_provider.dart

import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/manager/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final _service = NotificationService.instance;

  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _service.streamNotifications(userId);
  }

  Stream<int> streamUnreadCount(String userId) {
    return _service.streamUnreadCount(userId);
  }

  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    await _service.markAsRead(
      userId: userId,
      notificationId: notificationId,
    );
  }

  Future<void> markAllAsRead(String userId) async {
    await _service.markAllAsRead(userId);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _service.deleteNotification(notificationId);
  }
}
