import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/unlink_request_model.dart';
import '../status_service.dart';
import 'notification_service.dart';
import '../../models/notification_model.dart';

class UnlinkRequestService {
  UnlinkRequestService._();
  static final UnlinkRequestService instance = UnlinkRequestService._();

  final _db = FirebaseFirestore.instance;
  final _notifSvc = NotificationService.instance;

  // ───────────────── OWNER SEND REQUEST ─────────────────
  // Dùng StatusService vì cần check existing bằng DocumentReference

  Future<String?> sendUnlinkRequest({
    required String roomId,
    required String roomNumber,
    required String bhName,
    required String ownerId,
    required String ownerName,
    required String tenantId,
  }) async {
    try {
      final pendingStatus = await StatusService.getStatusRef(
        type: 'room',
        key: 'roompending',
      );

      final existing = await _db
          .collection('request')
          .where('id_room', isEqualTo: _db.doc('room/$roomId'))
          .where('status', isEqualTo: pendingStatus)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return 'Yêu cầu đang chờ xử lý';
      }

      final now = DateTime.now();

      await _db.collection('request').add(
            UnlinkRequestModel(
              requestId: '',
              roomId: roomId,
              roomNumber: roomNumber,
              bhName: bhName,
              ownerId: ownerId,
              tenantId: tenantId,
              status: UnlinkRequestStatus.roompending,
              createdAt: now,
            ).toFirestore(_db),
          );

      await _notifSvc.createNotification(
        receiverId: tenantId,
        senderId: ownerId,
        type: NotificationType.room,
        content: '$ownerName muốn hủy liên kết phòng $roomNumber',
      );

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ───────────────── ACCEPT REQUEST ─────────────────
  // Dùng StatusService cho room (type: room, key: available)
  // Request status dùng string thẳng vì không có type: 'request' trong Firestore

  Future<String?> acceptUnlink({
    required String requestId,
    required String roomId,
    required String tenantId,
    required String tenantName,
    required String ownerId,
    required String roomNumber,
  }) async {
    try {
      final availableStatus = await StatusService.getStatusRef(
        type: 'room',
        key: 'available',
      );

      final batch = _db.batch();
      final now = Timestamp.now();

      // Update request status bằng string thẳng
      batch.update(
        _db.collection('request').doc(requestId),
        {'status': 'accepted', 'updated_at': now},
      );

      // Reset room về available dùng DocumentReference
      batch.update(
        _db.collection('room').doc(roomId),
        {
          'status': availableStatus,
          'tenant_id': null,
          'tenant_name': null,
          'updated_at': now,
        },
      );

      await batch.commit();

      await _notifSvc.createNotification(
        receiverId: ownerId,
        senderId: tenantId,
        type: NotificationType.room,
        content: '$tenantName đã đồng ý rời phòng $roomNumber',
      );

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ───────────────── REJECT REQUEST ─────────────────
  // Request status dùng string thẳng

  Future<String?> rejectUnlink({
    required String requestId,
    required String tenantId,
    required String tenantName,
    required String ownerId,
    required String roomNumber,
  }) async {
    try {
      await _db.collection('request').doc(requestId).update({
        'status': 'rejected',
        'updated_at': Timestamp.now(),
      });

      await _notifSvc.createNotification(
        receiverId: ownerId,
        senderId: tenantId,
        type: NotificationType.room,
        content: '$tenantName từ chối rời phòng $roomNumber',
      );

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ───────────────── CANCEL REQUEST (owner hủy lại) ─────────────────

  Future<String?> cancelUnlinkRequest(String requestId) async {
    try {
      await _db.collection('request').doc(requestId).delete();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ───────────────── STREAM PENDING FOR ROOM ─────────────────

  Stream<UnlinkRequestModel?> streamPendingRequestForRoom(String roomId) {
    return _db
        .collection('request')
        .where('id_room', isEqualTo: _db.doc('room/$roomId'))
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final model = UnlinkRequestModel.fromDoc(snap.docs.first);
      return model.status == UnlinkRequestStatus.roompending ? model : null;
    });
  }

  // ───────────────── STREAM PENDING FOR TENANT ─────────────────

  Stream<List<UnlinkRequestModel>> streamPendingRequestsForTenant(
    String tenantId,
  ) {
    return _db
        .collection('request')
        .where('id_tenant', isEqualTo: _db.doc('users/$tenantId'))
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => UnlinkRequestModel.fromDoc(d))
            .where((e) => e.status == UnlinkRequestStatus.roompending)
            .toList());
  }

  // ───────────────── STREAM ALL FOR OWNER ─────────────────

  Stream<List<UnlinkRequestModel>> streamRequestsForOwner(String ownerId) {
    return _db
        .collection('request')
        .where('id_owner', isEqualTo: _db.doc('users/$ownerId'))
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => UnlinkRequestModel.fromDoc(d)).toList());
  }
}
