import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/unlink_request_model.dart';
import 'notification_service.dart';
import '../../models/notification_model.dart';

/// Xử lý toàn bộ flow hủy liên kết giữa owner và tenant.
class UnlinkRequestService {
  UnlinkRequestService._();
  static final UnlinkRequestService instance = UnlinkRequestService._();

  final _db = FirebaseFirestore.instance;
  final _notifSvc = NotificationService.instance;

  // ── Owner gửi yêu cầu hủy liên kết ───────────────────────────────────
  /// 1. Tạo document trong collection `request`
  /// 2. Gửi thông báo đến tenant
  Future<String?> sendUnlinkRequest({
    required String roomId,
    required String roomNumber,
    required String bhName,
    required String ownerId,
    required String ownerName,
    required String tenantId,
  }) async {
    try {
      // Kiểm tra đã có request pending chưa
      final existing = await _db
          .collection('request')
          .where('id_room', isEqualTo: _db.doc('room/$roomId'))
          .where('status', isEqualTo: _db.doc('status/pending'))
          .get();

      if (existing.docs.isNotEmpty) {
        return 'Đã có yêu cầu hủy liên kết đang chờ xử lý';
      }

      final now = DateTime.now();

      // Tạo request
      final requestRef = await _db.collection('request').add(
            UnlinkRequestModel(
              requestId: '',
              roomId: roomId,
              roomNumber: roomNumber,
              bhName: bhName,
              ownerId: ownerId,
              tenantId: tenantId,
              status: UnlinkRequestStatus.pending,
              createdAt: now,
            ).toFirestore(_db),
          );

      // Gửi thông báo cho tenant
      await _notifSvc.sendToUser(
        tenantId,
        NotificationModel(
          notifId: '',
          receiverId: tenantId,
          senderId: ownerId,
          type: NotificationType.unlinkRequest,
          content:
              '$ownerName yêu cầu kết thúc hợp đồng phòng $roomNumber - $bhName',
          isRead: false,
          createdAt: now,
          requestId: requestRef.id,
          roomId: roomId,
          roomNumber: roomNumber,
        ),
      );

      return null;
    } catch (e) {
      return 'Gửi yêu cầu thất bại: $e';
    }
  }

  // ── Tenant xác nhận hủy liên kết ─────────────────────────────────────
  /// 1. Cập nhật request status → accepted
  /// 2. Cập nhật room: status → empty, tenant_id = null, tenant_name = null
  ///    (last_elec và last_water giữ nguyên)
  /// 3. Gửi thông báo về cho owner
  Future<String?> acceptUnlink({
    required String requestId,
    required String roomId,
    required String tenantId,
    required String tenantName,
    required String ownerId,
    required String roomNumber,
  }) async {
    try {
      final batch = _db.batch();
      final now = DateTime.now();

      // Cập nhật request
      batch.update(
        _db.collection('request').doc(requestId),
        {'status': _db.doc('status/accepted')},
      );

      // Cập nhật phòng về empty
      batch.update(
        _db.collection('room').doc(roomId),
        {
          'status': _db.doc('status/available'),
          'tenant_id': null,
          'tenant_name': null,
          'update_time': Timestamp.fromDate(now),
          // last_elec_reading và last_water_reading KHÔNG reset
        },
      );

      await batch.commit();

      // Gửi thông báo về cho owner
      await _notifSvc.sendToUser(
        ownerId,
        NotificationModel(
          notifId: '',
          receiverId: ownerId,
          senderId: tenantId,
          type: NotificationType.unlinkAccepted,
          content:
              '$tenantName đã xác nhận kết thúc hợp đồng phòng $roomNumber',
          isRead: false,
          createdAt: now,
          requestId: requestId,
          roomId: roomId,
          roomNumber: roomNumber,
        ),
      );

      return null;
    } catch (e) {
      return 'Xác nhận thất bại: $e';
    }
  }

  // ── Tenant từ chối hủy liên kết ──────────────────────────────────────
  /// 1. Cập nhật request status → rejected
  /// 2. Gửi thông báo về cho owner
  Future<String?> rejectUnlink({
    required String requestId,
    required String roomId,
    required String tenantId,
    required String tenantName,
    required String ownerId,
    required String roomNumber,
  }) async {
    try {
      // Cập nhật request
      await _db.collection('request').doc(requestId).update(
        {'status': _db.doc('status/rejected')},
      );

      // Gửi thông báo về cho owner
      await _notifSvc.sendToUser(
        ownerId,
        NotificationModel(
          notifId: '',
          receiverId: ownerId,
          senderId: tenantId,
          type: NotificationType.unlinkRejected,
          content:
              '$tenantName đã từ chối yêu cầu kết thúc hợp đồng phòng $roomNumber',
          isRead: false,
          createdAt: DateTime.now(),
          requestId: requestId,
          roomId: roomId,
          roomNumber: roomNumber,
        ),
      );

      return null;
    } catch (e) {
      return 'Từ chối thất bại: $e';
    }
  }

  // ── Stream request đang pending của 1 tenant ──────────────────────────
  Stream<List<UnlinkRequestModel>> streamPendingRequestsForTenant(
      String tenantId) {
    return _db
        .collection('request')
        .where('id_tenant', isEqualTo: _db.doc('users/$tenantId'))
        .where('status', isEqualTo: _db.doc('status/pending'))
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => UnlinkRequestModel.fromDoc(d)).toList());
  }

  // ── Stream tất cả request của 1 owner ────────────────────────────────
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
