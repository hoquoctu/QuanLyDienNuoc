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
        type: 'request',
        key: 'pending',
      );

      // check existing pending request
      final existing = await _db
          .collection('request')
          .where(
            'id_room',
            isEqualTo: _db.doc('room/$roomId'),
          )
          .where(
            'status',
            isEqualTo: pendingStatus,
          )
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

      // notification
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

  Future<String?> acceptUnlink({
    required String requestId,
    required String roomId,
    required String tenantId,
    required String tenantName,
    required String ownerId,
    required String roomNumber,
  }) async {
    try {
      final acceptedStatus = await StatusService.getStatusRef(
        type: 'request',
        key: 'accepted',
      );

      final availableStatus = await StatusService.getStatusRef(
        type: 'room',
        key: 'available',
      );

      final batch = _db.batch();

      final now = Timestamp.now();

      // update request
      batch.update(
        _db.collection('request').doc(
              requestId,
            ),
        {
          'status': acceptedStatus,
          'updated_at': now,
        },
      );

      // reset room
      batch.update(
        _db.collection('room').doc(roomId),
        {
          'status': availableStatus,
          'tenant_id': null,
          'updated_at': now,
        },
      );

      await batch.commit();

      // notify owner
      await _notifSvc.createNotification(
        receiverId: ownerId,
        senderId: tenantId,
        type: NotificationType.room,
        content: '$tenantName đã rời phòng $roomNumber',
      );

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ───────────────── REJECT REQUEST ─────────────────

  Future<String?> rejectUnlink({
    required String requestId,
    required String tenantId,
    required String tenantName,
    required String ownerId,
    required String roomNumber,
  }) async {
    try {
      final rejectedStatus = await StatusService.getStatusRef(
        type: 'request',
        key: 'rejected',
      );

      await _db.collection('request').doc(requestId).update({
        'status': rejectedStatus,
        'updated_at': Timestamp.now(),
      });

      // notify owner
      await _notifSvc.createNotification(
        receiverId: ownerId,
        senderId: tenantId,
        type: NotificationType.room,
        content: '$tenantName từ chối hủy phòng $roomNumber',
      );

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ───────────────── TENANT PENDING REQUESTS ─────────────────

  Stream<List<UnlinkRequestModel>> streamPendingRequestsForTenant(
    String tenantId,
  ) {
    return _db
        .collection('request')
        .where(
          'id_tenant',
          isEqualTo: _db.doc('users/$tenantId'),
        )
        .orderBy(
          'created_at',
          descending: true,
        )
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => UnlinkRequestModel.fromDoc(d),
              )
              .where(
                (e) => e.status == UnlinkRequestStatus.roompending,
              )
              .toList(),
        );
  }

  // ───────────────── OWNER REQUESTS ─────────────────

  Stream<List<UnlinkRequestModel>> streamRequestsForOwner(
    String ownerId,
  ) {
    return _db
        .collection('request')
        .where(
          'id_owner',
          isEqualTo: _db.doc('users/$ownerId'),
        )
        .orderBy(
          'created_at',
          descending: true,
        )
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => UnlinkRequestModel.fromDoc(d),
              )
              .toList(),
        );
  }
}
