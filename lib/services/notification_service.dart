import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _db = FirebaseFirestore.instance;

  /// Stream danh sách thông báo của user dựa trên receiver_id
  /// Item là subcollection của notifications: notifications/{notifId}/Item/{itemId}
  /// => Phải dùng collectionGroup để query across all subcollections
  Stream<List<NotificationItem>> streamNotifications(String userId) {
    final userRef = _db.doc('users/$userId');
    print('[NotificationService] Stream cho user: $userId');
    print('[NotificationService] userRef path: ${userRef.path}');

    return _db
        .collectionGroup('Item')
        .where('receiver_id', isEqualTo: userRef)
        .snapshots()
        .asyncMap((receiverSnap) async {
      print('[NotificationService] Nhận ${receiverSnap.docs.length} receiver docs');

      if (receiverSnap.docs.isEmpty) return <NotificationItem>[];

      final items = <NotificationItem>[];

      for (final receiverDoc in receiverSnap.docs) {
        final receiver = NotificationReceiverModel.fromDoc(receiverDoc);

        // Lấy notification parent document
        // Path: notifications/{notifId}/Item/{itemId}
        // => parent.parent = notifications/{notifId}
        final notifRef = receiverDoc.reference.parent.parent;
        if (notifRef == null) {
          print('[NotificationService] notifRef null cho doc: ${receiverDoc.id}');
          continue;
        }

        try {
          final notifDoc = await notifRef.get();
          if (!notifDoc.exists) {
            print('[NotificationService] Notification không tồn tại: ${notifRef.path}');
            continue;
          }

          final notification = NotificationModel.fromDoc(notifDoc);
          items.add(NotificationItem(
            notification: notification,
            receiver: receiver,
          ));
        } catch (e) {
          print('[NotificationService] Lỗi lấy notification: $e');
        }
      }

      // Sort mới nhất trước
      items.sort((a, b) =>
          b.notification.createdAt.compareTo(a.notification.createdAt));

      print('[NotificationService] Trả về ${items.length} thông báo');
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
      final snap = await _db
          .collectionGroup('Item')
          .where('receiver_id', isEqualTo: userRef)
          .where('is_read', isEqualTo: false)
          .get();

      if (snap.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'is_read': true});
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
