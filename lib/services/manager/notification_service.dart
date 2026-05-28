import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quanlydiennc_app/providers/nofitication_provider.dart';

import '../../models/notification_model.dart';

/// FIREBASE STRUCTURE
///
/// notifications/{notificationId}
///    ├── content
///    ├── type
///    ├── sender_id
///    ├── created_at
///    └── item/{itemId}
///          ├── receiver_id
///          └── is_read

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ───────────────── CREATE SINGLE ─────────────────

  Future<String?> createNotification({
    required String receiverId,
    required String senderId,
    required NotificationType type,
    required String content,
  }) async {
    try {
      final notifRef = _db.collection('notifications').doc();

      final itemRef = notifRef.collection('item').doc();

      // notification data
      final notif = NotificationModel(
        notifId: notifRef.id,
        content: content,
        type: type,
        senderId: senderId,
        createdAt: DateTime.now(),
      );

      // create notification
      await notifRef.set(
        notif.toFirestore(_db),
      );

      // create receiver item
      await itemRef.set({
        'receiver_id': _db.doc('users/$receiverId'),
        'is_read': false,
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ───────────────── BROADCAST ─────────────────

  Future<String?> broadcastNotification({
    required List<String> receiverIds,
    required String senderId,
    required NotificationType type,
    required String content,
  }) async {
    try {
      final notifRef = _db.collection('notifications').doc();

      final batch = _db.batch();

      // create main notification
      final notif = NotificationModel(
        notifId: notifRef.id,
        content: content,
        type: type,
        senderId: senderId,
        createdAt: DateTime.now(),
      );

      batch.set(
        notifRef,
        notif.toFirestore(_db),
      );

      // create item for each receiver
      for (final receiverId in receiverIds) {
        final itemRef = notifRef.collection('item').doc();

        batch.set(itemRef, {
          'receiver_id': _db.doc('users/$receiverId'),
          'is_read': false,
        });
      }

      await batch.commit();

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ───────────────── USER NOTIFICATIONS ─────────────────

  Stream<List<NotificationModel>> streamNotifications(
    String userId,
  ) {
    return _db
        .collectionGroup('item')
        .where(
          'receiver_id',
          isEqualTo: _db.doc('users/$userId'),
        )
        .snapshots()
        .asyncMap((snap) async {
      List<NotificationModel> result = [];

      for (final itemDoc in snap.docs) {
        final notifDoc = await itemDoc.reference.parent.parent!.get();

        if (!notifDoc.exists) continue;

        result.add(
          NotificationModel.fromDoc(
            notifDoc,
          ),
        );
      }

      result.sort(
        (a, b) => b.createdAt.compareTo(
          a.createdAt,
        ),
      );

      return result;
    });
  }

  // ───────────────── MARK AS READ ─────────────────

  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    final itemSnap = await _db
        .collection('notifications')
        .doc(notificationId)
        .collection('item')
        .where(
          'receiver_id',
          isEqualTo: _db.doc('users/$userId'),
        )
        .limit(1)
        .get();

    if (itemSnap.docs.isEmpty) return;

    await itemSnap.docs.first.reference.update({
      'is_read': true,
    });
  }

  // ───────────────── MARK ALL AS READ ─────────────────

  Future<void> markAllAsRead(
    String userId,
  ) async {
    final snap = await _db
        .collectionGroup('item')
        .where(
          'receiver_id',
          isEqualTo: _db.doc('users/$userId'),
        )
        .where(
          'is_read',
          isEqualTo: false,
        )
        .get();

    final batch = _db.batch();

    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'is_read': true,
      });
    }

    await batch.commit();
  }

  // ───────────────── UNREAD COUNT ─────────────────

  Stream<int> streamUnreadCount(
    String userId,
  ) {
    return _db
        .collectionGroup('item')
        .where(
          'receiver_id',
          isEqualTo: _db.doc('users/$userId'),
        )
        .where(
          'is_read',
          isEqualTo: false,
        )
        .snapshots()
        .map(
          (snap) => snap.size,
        );
  }

  // ───────────────── DELETE ─────────────────

  Future<void> deleteNotification(
    String notificationId,
  ) async {
    final itemSnap = await _db
        .collection('notifications')
        .doc(notificationId)
        .collection('item')
        .get();

    final batch = _db.batch();

    for (final doc in itemSnap.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(
      _db.collection('notifications').doc(notificationId),
    );

    await batch.commit();
  }

  Stream<List<NotificationItem>> streamNotificationsWithRead(String userId) {
    return _db
        .collectionGroup('item')
        .where('receiver_id', isEqualTo: _db.doc('users/$userId'))
        .snapshots()
        .asyncMap((snap) async {
      List<NotificationItem> result = [];

      for (final itemDoc in snap.docs) {
        final notifDoc = await itemDoc.reference.parent.parent!.get();
        if (!notifDoc.exists) continue;

        final isRead = itemDoc.data()['is_read'] as bool? ?? false;

        result.add(NotificationItem(
          notification: NotificationModel.fromDoc(notifDoc),
          isRead: isRead,
        ));
      }

      result.sort((a, b) =>
          b.notification.createdAt.compareTo(a.notification.createdAt));
      return result;
    });
  }
}
