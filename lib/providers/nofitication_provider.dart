import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/manager/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final _service = NotificationService.instance;

  // ── THÊM: state ──────────────────────────────────────────────────────────
  List<NotificationItem> _items = [];
  bool _loading = false;
  String? _error;
  StreamSubscription? _sub;

  List<NotificationItem> get items => _items;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasUnread => _items.any((i) => !i.isRead);

  void init(String userId) {
    _loading = true;
    notifyListeners();

    _sub?.cancel();
    _sub = _service.streamNotificationsWithRead(userId).listen(
      (items) {
        _items = items;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }
  // ─────────────────────────────────────────────────────────────────────────

  // ── GIỮ NGUYÊN ───────────────────────────────────────────────────────────
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
  // ─────────────────────────────────────────────────────────────────────────

  // ── THÊM: overload markAsRead cho NotificationItem ───────────────────────
  Future<void> markAsReadItem({
    required String userId,
    required NotificationItem item,
  }) async {
    await _service.markAsRead(
      userId: userId,
      notificationId: item.notification.notifId,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ── THÊM: model phụ ──────────────────────────────────────────────────────────
class NotificationItem {
  final NotificationModel notification;
  final bool isRead;
  const NotificationItem({required this.notification, required this.isRead});
}
