import 'package:cloud_firestore/cloud_firestore.dart';

enum BhRoomStatus {
  empty, // key: available
  occupied, // key: occupied
  pending, // key: pending
  inactive, // key: inactive
}

/// Model phòng trọ — map collection `room` trên Firestore
/// boardingHouse_id lưu dạng DocumentReference
class BhRoomModel {
  final String bhRoomId;
  final String bhId;
  String bhRoomNumber;
  BhRoomStatus bhRoomStatus;

  String? bhRoomTenantId;
  String? bhRoomTenantName;
  String? bhRoomJoinCode;
  DateTime? bhRoomJoinCodeExpiry;
  DateTime? bhRoomTenantSince;

  double bhRoomLastElec;
  double bhRoomLastWater;

  BhRoomModel({
    required this.bhRoomId,
    required this.bhId,
    required this.bhRoomNumber,
    this.bhRoomStatus = BhRoomStatus.empty,
    this.bhRoomTenantId,
    this.bhRoomTenantName,
    this.bhRoomJoinCode,
    this.bhRoomJoinCodeExpiry,
    this.bhRoomTenantSince,
    this.bhRoomLastElec = 0,
    this.bhRoomLastWater = 0,
  });

  bool get isBhRoomJoinCodeValid =>
      bhRoomJoinCode != null &&
      bhRoomJoinCodeExpiry != null &&
      DateTime.now().isBefore(bhRoomJoinCodeExpiry!);

  // ── Từ Firestore doc ───────────────────────────────────────────────────
  factory BhRoomModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    // boardingHouse_id là DocumentReference
    final bhRef = d['boardingHouse_id'];
    String bhId = '';
    if (bhRef is DocumentReference) {
      bhId = bhRef.id;
    } else if (bhRef is String) {
      bhId = bhRef.split('/').last;
    }

    // status_id là DocumentReference: /status/available | /status/occupied ...
    final statusRef = d['status_id'];
    String statusKey = 'available';
    if (statusRef is DocumentReference) {
      statusKey = statusRef.id; // lấy document ID = key
    } else if (statusRef is String) {
      statusKey = statusRef.split('/').last;
    }

    return BhRoomModel(
      bhRoomId: doc.id,
      bhId: bhId,
      bhRoomNumber: d['room_number'] ?? '',
      bhRoomStatus: _statusFromKey(statusKey),
      bhRoomTenantId: d['tenant_id'],
      bhRoomTenantName: d['tenant_name'],
      bhRoomJoinCode: d['join_code'],
      bhRoomJoinCodeExpiry: (d['join_code_expiry'] as Timestamp?)?.toDate(),
      bhRoomTenantSince: (d['tenant_since'] as Timestamp?)?.toDate(),
      bhRoomLastElec: (d['last_elec_reading'] ?? 0).toDouble(),
      bhRoomLastWater: (d['last_water_reading'] ?? 0).toDouble(),
    );
  }

  // ── Ghi lên Firestore ──────────────────────────────────────────────────
  Map<String, dynamic> toFirestore(FirebaseFirestore db) => {
        'room_number': bhRoomNumber,
        'boardingHouse_id': db.doc('boardingHouse/$bhId'),
        'status_id': db.doc('status/${statusToKey(bhRoomStatus)}'),
        if (bhRoomTenantId != null) 'tenant_id': bhRoomTenantId,
        if (bhRoomTenantName != null) 'tenant_name': bhRoomTenantName,
        if (bhRoomJoinCode != null) 'join_code': bhRoomJoinCode,
        if (bhRoomJoinCodeExpiry != null)
          'join_code_expiry': Timestamp.fromDate(bhRoomJoinCodeExpiry!),
        if (bhRoomTenantSince != null)
          'tenant_since': Timestamp.fromDate(bhRoomTenantSince!),
        'last_elec_reading': bhRoomLastElec,
        'last_water_reading': bhRoomLastWater,
      };

  // ── Key mapping — khớp với StatusCache type=room ───────────────────────
  static BhRoomStatus _statusFromKey(String key) {
    switch (key) {
      case 'occupied':
        return BhRoomStatus.occupied;
      case 'pending':
        return BhRoomStatus.pending;
      case 'inactive':
        return BhRoomStatus.inactive;
      default: // 'available'
        return BhRoomStatus.empty;
    }
  }

  /// Dùng bởi StatusBadge và toFirestore
  static String statusToKey(BhRoomStatus s) {
    switch (s) {
      case BhRoomStatus.occupied:
        return 'occupied';
      case BhRoomStatus.pending:
        return 'pending';
      case BhRoomStatus.inactive:
        return 'inactive';
      case BhRoomStatus.empty:
        return 'available';
    }
  }
}
