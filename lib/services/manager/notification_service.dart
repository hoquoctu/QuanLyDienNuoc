import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notification_model.dart';

/// Xử lý toàn bộ việc gửi và lấy thông báo.
/// Cấu trúc Firestore:
///   notifications/{userId}/item/{notifId}
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _db = FirebaseFirestore.instance;

  // ── Stream thông báo của 1 user (mới nhất trước) ──────────────────────
  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _db
        .collection('notifications')
        .doc(userId)
        .collection('item')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => NotificationModel.fromDoc(userId, d))
            .toList());
  }

  // ── Gửi thông báo đến 1 user ──────────────────────────────────────────
  Future<String?> sendToUser(
    String receiverId,
    NotificationModel notif,
  ) async {
    try {
      await _db
          .collection('notifications')
          .doc(receiverId)
          .collection('item')
          .add(notif.toFirestore(_db, receiverId));
      return null;
    } catch (e) {
      return 'Gửi thông báo thất bại: $e';
    }
  }

  // ── Gửi thông báo cập nhật giá đến tất cả tenant trong 1 dãy trọ ─────
  /// Dùng khi owner cập nhật giá điện/nước:
  /// 1. Lấy tất cả phòng của dãy đó có status occupied
  /// 2. Gửi thông báo đến từng tenant
  Future<String?> broadcastPriceUpdate({
    required String bhId,
    required String bhName,
    required String ownerId,
    required String content,
  }) async {
    try {
      final bhRef = _db.doc('boardingHouse/$bhId');
      final statusRef = _db.doc('status/occupied');

      // Lấy tất cả phòng occupied trong dãy
      final roomSnap = await _db
          .collection('room')
          .where('boarding_house', isEqualTo: bhRef)
          .where('status', isEqualTo: statusRef)
          .get();

      if (roomSnap.docs.isEmpty) return null;

      final batch = _db.batch();
      final now = DateTime.now();

      for (final roomDoc in roomSnap.docs) {
        final data = roomDoc.data();
        final tenantRef = data['tenant_id'];
        if (tenantRef == null || tenantRef is! DocumentReference) continue;

        final tenantId = tenantRef.id;
        final notifRef = _db
            .collection('notifications')
            .doc(tenantId)
            .collection('item')
            .doc();

        final notif = NotificationModel(
          notifId: notifRef.id,
          receiverId: tenantId,
          senderId: ownerId,
          type: NotificationType.priceUpdate,
          content: content,
          isRead: false,
          createdAt: now,
          roomId: roomDoc.id,
          roomNumber: data['number_room'] as String?,
        );

        batch.set(notifRef, notif.toFirestore(_db, tenantId));
      }

      await batch.commit();
      return null;
    } catch (e) {
      return 'Broadcast thất bại: $e';
    }
  }

  // ── Đánh dấu đã đọc ───────────────────────────────────────────────────
  Future<void> markAsRead(String userId, String notifId) async {
    await _db
        .collection('notifications')
        .doc(userId)
        .collection('item')
        .doc(notifId)
        .update({'is_read': true});
  }

  // ── Đánh dấu tất cả đã đọc ───────────────────────────────────────────
  Future<void> markAllAsRead(String userId) async {
    final snap = await _db
        .collection('notifications')
        .doc(userId)
        .collection('item')
        .where('is_read', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'is_read': true});
    }
    await batch.commit();
  }

  // ── Số thông báo chưa đọc ─────────────────────────────────────────────
  Stream<int> streamUnreadCount(String userId) {
    return _db
        .collection('notifications')
        .doc(userId)
        .collection('item')
        .where('is_read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.size);
  }
}
