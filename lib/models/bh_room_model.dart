import 'package:cloud_firestore/cloud_firestore.dart';

enum BhRoomStatus {
  available, // key: available
  occupied, // key: occupied
  waiting, // key: pending
  inactive, // key: inactive
}

class BhRoomModel {
  final String bhRoomId;
  final String bhId;
  String bhRoomNumber;
  BhRoomStatus bhRoomStatus;

  // Tenant — lưu dạng reference uid, null nếu không có ai thuê
  String? bhRoomTenantId;
  String? bhRoomTenantName;
  // Join code
  String? bhRoomCode; // code: string|null
  DateTime? bhRoomTimeStart; // time_start: timestamp|null (lúc tạo mã)

  // Thời điểm cập nhật
  DateTime? bhRoomUpdateTime; // update_time: timestamp

  // Chỉ số điện nước (giữ lại cho sau)
  double bhRoomLastElec;
  double bhRoomLastWater;

  BhRoomModel({
    required this.bhRoomId,
    required this.bhId,
    required this.bhRoomNumber,
    this.bhRoomStatus = BhRoomStatus.available,
    this.bhRoomTenantId,
    this.bhRoomTenantName,
    this.bhRoomCode,
    this.bhRoomTimeStart,
    this.bhRoomUpdateTime,
    this.bhRoomLastElec = 0,
    this.bhRoomLastWater = 0,
  });

  // Code còn hiệu lực không (30 phút kể từ time_start)
  bool get isBhRoomCodeValid {
    if (bhRoomCode == null || bhRoomTimeStart == null) return false;
    final expiry = bhRoomTimeStart!.add(const Duration(minutes: 2));
    return DateTime.now().isBefore(expiry);
  }

  // Thời gian hết hạn (để đếm ngược)
  DateTime? get bhRoomCodeExpiry =>
      bhRoomTimeStart?.add(const Duration(minutes: 2));

  // ── Từ Firestore doc ───────────────────────────────────────────────────
  factory BhRoomModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    // boarding_house: DocumentReference
    final bhRef = d['boarding_house'];
    String bhId = '';
    if (bhRef is DocumentReference) {
      bhId = bhRef.id;
    } else if (bhRef is String) {
      bhId = bhRef.split('/').last;
    }

    // status: DocumentReference → /status/available | occupied | pending | inactive
    final statusRef = d['status'];
    String statusKey = 'available';
    if (statusRef is DocumentReference) {
      statusKey = statusRef.id;
    } else if (statusRef is String) {
      statusKey = statusRef.split('/').last;
    }

    // tenant_id: DocumentReference|null → lấy uid
    final tenantRef = d['tenant_id'];
    String? tenantId;
    if (tenantRef is DocumentReference) {
      tenantId = tenantRef.id;
    } else if (tenantRef is String) {
      tenantId = tenantRef.split('/').last;
    }

    return BhRoomModel(
      bhRoomId: doc.id,
      bhId: bhId,
      bhRoomNumber: d['number_room'] ?? '',
      bhRoomStatus: _statusFromKey(statusKey),
      bhRoomTenantId: tenantId,
      bhRoomTenantName: d['tenant_name'],
      bhRoomCode: d['code'],
      bhRoomTimeStart: (d['time_start'] as Timestamp?)?.toDate(),
      bhRoomUpdateTime: (d['update_time'] as Timestamp?)?.toDate(),
      bhRoomLastElec: (d['last_elec_reading'] ?? 0).toDouble(),
      bhRoomLastWater: (d['last_water_reading'] ?? 0).toDouble(),
    );
  }

  // ── Ghi lên Firestore ──────────────────────────────────────────────────
  Map<String, dynamic> toFirestore(FirebaseFirestore db) => {
        'number_room': bhRoomNumber,
        'boarding_house': db.doc('boardingHouse/$bhId'),
        'status': db.doc('status/${statusToKey(bhRoomStatus)}'),
        'tenant_id':
            bhRoomTenantId != null ? db.doc('users/$bhRoomTenantId') : null,
        'tenant_name': bhRoomTenantName,
        'code': bhRoomCode,
        'time_start': bhRoomTimeStart != null
            ? Timestamp.fromDate(bhRoomTimeStart!)
            : null,
        'update_time': Timestamp.fromDate(bhRoomUpdateTime ?? DateTime.now()),
        'last_elec_reading': bhRoomLastElec,
        'last_water_reading': bhRoomLastWater,
      };

  // ── Key mapping ────────────────────────────────────────────────────────
  static BhRoomStatus _statusFromKey(String key) {
    switch (key) {
      case 'occupied':
        return BhRoomStatus.occupied;
      case 'roompending':
        return BhRoomStatus.waiting;
      case 'inactive':
        return BhRoomStatus.inactive;
      default:
        return BhRoomStatus.available;
    }
  }

  static String statusToKey(BhRoomStatus s) {
    switch (s) {
      case BhRoomStatus.occupied:
        return 'occupied';
      case BhRoomStatus.waiting:
        return 'roompending';
      case BhRoomStatus.inactive:
        return 'inactive';
      case BhRoomStatus.available:
        return 'available';
    }
  }
}
