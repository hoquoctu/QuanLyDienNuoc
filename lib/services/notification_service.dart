import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _db = FirebaseFirestore.instance;

  /// Stream danh sách thông báo của user
  /// Query notifications collection, rồi kiểm tra Item subcollection của từng cái
  /// (tránh collectionGroup query cần composite index)
  Stream<List<NotificationItem>> streamNotifications(String userId) {
    final userRef = _db.doc('users/$userId');

    return _db.collection('notifications').snapshots().asyncMap((notifSnap) async {
      final futures = notifSnap.docs.map((notifDoc) async {
        try {
          final receiverSnap = await notifDoc.reference
              .collection('Item')
              .where('receiver_id', isEqualTo: userRef)
              .limit(1)
              .get();
          if (receiverSnap.docs.isEmpty) return null;
          final receiver = NotificationReceiverModel.fromDoc(receiverSnap.docs.first);
          final notification = NotificationModel.fromDoc(notifDoc);
          return NotificationItem(notification: notification, receiver: receiver);
        } catch (_) {
          return null;
        }
      });

      final results = await Future.wait(futures);
      final items = results.whereType<NotificationItem>().toList();
      items.sort((a, b) =>
          b.notification.createdAt.compareTo(a.notification.createdAt));
      return items;
    });
  }

  /// Đánh dấu thông báo đã đọc
  Future<void> markAsRead(String notifId, String receiverItemId) async {
    try {
      await _db
          .collection('notifications')
          .doc(notifId)
          .collection('Item')
          .doc(receiverItemId)
          .update({'is_read': true});
    } catch (e) {
      print('[NotificationService] Lỗi markAsRead: $e');
    }
  }

  /// Đánh dấu tất cả đã đọc
  Future<void> markAllAsRead(String userId) async {
    try {
      final userRef = _db.doc('users/$userId');
      final notifSnap = await _db.collection('notifications').get();

      final batch = _db.batch();
      for (final notifDoc in notifSnap.docs) {
        final receiverSnap = await notifDoc.reference
            .collection('Item')
            .where('receiver_id', isEqualTo: userRef)
            .where('is_read', isEqualTo: false)
            .limit(1)
            .get();
        for (final doc in receiverSnap.docs) {
          batch.update(doc.reference, {'is_read': true});
        }
      }
      await batch.commit();
    } catch (e) {
      print('[NotificationService] Lỗi markAllAsRead: $e');
    }
  }
}

/// Kết hợp thông báo + trạng thái đọc
class NotificationItem {
  final NotificationModel notification;
  final NotificationReceiverModel receiver;

  const NotificationItem({
    required this.notification,
    required this.receiver,
  });

  bool get isRead => receiver.isRead;
  String get notifId => notification.notifId;
  String get receiverItemId => receiver.itemId;
}
