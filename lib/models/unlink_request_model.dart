import 'package:cloud_firestore/cloud_firestore.dart';

enum UnlinkRequestStatus {
  pending, // chờ tenant xác nhận
  accepted, // tenant đồng ý
  rejected, // tenant từ chối
}

class UnlinkRequestModel {
  final String requestId;
  final String roomId;
  final String roomNumber;
  final String bhName;
  final String ownerId;
  final String tenantId;
  final UnlinkRequestStatus status;
  final DateTime createdAt;

  const UnlinkRequestModel({
    required this.requestId,
    required this.roomId,
    required this.roomNumber,
    required this.bhName,
    required this.ownerId,
    required this.tenantId,
    required this.status,
    required this.createdAt,
  });

  factory UnlinkRequestModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    final roomRef = d['id_room'];
    String roomId = '';
    if (roomRef is DocumentReference) roomId = roomRef.id;

    final ownerRef = d['id_owner'];
    String ownerId = '';
    if (ownerRef is DocumentReference) ownerId = ownerRef.id;

    final tenantRef = d['id_tenant'];
    String tenantId = '';
    if (tenantRef is DocumentReference) tenantId = tenantRef.id;

    final statusRef = d['status'];
    String statusKey = 'pending';
    if (statusRef is DocumentReference) {
      statusKey = statusRef.id;
    } else if (statusRef is String) {
      statusKey = statusRef;
    }

    return UnlinkRequestModel(
      requestId: doc.id,
      roomId: roomId,
      roomNumber: d['room_number'] as String? ?? '',
      bhName: d['bh_name'] as String? ?? '',
      ownerId: ownerId,
      tenantId: tenantId,
      status: _statusFromKey(statusKey),
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore(FirebaseFirestore db) => {
        'id_room': db.doc('room/$roomId'),
        'id_owner': db.doc('users/$ownerId'),
        'id_tenant': db.doc('users/$tenantId'),
        'room_number': roomNumber,
        'bh_name': bhName,
        'status': db.doc('status/${_statusToKey(status)}'),
        'created_at': Timestamp.fromDate(createdAt),
      };

  static UnlinkRequestStatus _statusFromKey(String key) {
    switch (key) {
      case 'accepted':
        return UnlinkRequestStatus.accepted;
      case 'rejected':
        return UnlinkRequestStatus.rejected;
      default:
        return UnlinkRequestStatus.pending;
    }
  }

  static String _statusToKey(UnlinkRequestStatus s) {
    switch (s) {
      case UnlinkRequestStatus.accepted:
        return 'accepted';
      case UnlinkRequestStatus.rejected:
        return 'rejected';
      case UnlinkRequestStatus.pending:
        return 'pending';
    }
  }
}
