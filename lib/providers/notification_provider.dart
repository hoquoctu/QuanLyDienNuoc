import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final _svc = NotificationService.instance;

  List<NotificationItem> _items = [];
  bool _loading = false;
  String? _error;
  StreamSubscription<List<NotificationItem>>? _sub;
  String? _currentUserId;

  List<NotificationItem> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  /// Số thông báo chưa đọc
  int get unreadCount => _items.where((i) => !i.isRead).length;

  /// Có thông báo chưa đọc?
  bool get hasUnread => unreadCount > 0;

  void initForUser(String userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    _sub?.cancel();
    _loading = true;
    _error = null;
    notifyListeners();

    _sub = _svc.streamNotifications(userId).listen(
      (items) {
        _items = items;
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Lỗi tải thông báo: $e';
        _loading = false;
        notifyListeners();
      },
    );
  }

  /// Đánh dấu 1 thông báo đã đọc
  Future<void> markAsRead(NotificationItem item) async {
    await _svc.markAsRead(item.notifId, item.receiverItemId);
  }

  /// Đánh dấu tất cả đã đọc
  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;
    await _svc.markAllAsRead(_currentUserId!);
  }

  void reset() {
    _sub?.cancel();
    _sub = null;
    _currentUserId = null;
    _items = [];
    _loading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
